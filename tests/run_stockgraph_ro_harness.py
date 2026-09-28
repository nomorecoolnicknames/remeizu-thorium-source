#!/usr/bin/env python3
"""Exercise real LOS16 shell control flow with a synthetic Soong backend only."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--platform', type=Path, required=True)
parser.add_argument('--private-root', type=Path, required=True)
parser.add_argument('--patch-root', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True, help='absent directory on tmpfs')
args = parser.parse_args()
PLATFORM = args.platform.resolve()
REPO = Path(__file__).resolve().parents[1]
PATCHES = args.patch_root.resolve()
ROOT = args.output.resolve()
ROOT.mkdir()
SRC = ROOT / 'src'
SRC.mkdir()
files = ['build/envsetup.sh', 'vendor/lineage/build/envsetup.sh',
         'vendor/lineage/build/tools/roomservice.py', 'vendor/lineage/vendorsetup.sh']
before = {}
for relative in files:
    target = SRC / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(PLATFORM / relative, target)
    target.chmod((PLATFORM / relative).stat().st_mode & 0o777)
    before[relative] = hashlib.sha256(target.read_bytes()).hexdigest()
for name in ['0002-roomservice-offline-snapshot.patch', '0003-vendorsetup-offline-snapshot.patch']:
    subprocess.run(['patch', '--batch', '--forward', '-p1', '-i', str(PATCHES / name)],
                   cwd=SRC, check=True, capture_output=True, text=True)
(SRC / 'build/make/core').mkdir(parents=True)
(SRC / 'build/make/core/envsetup.mk').touch()
(SRC / 'build/soong').mkdir()
fake = SRC / 'build/soong/soong_ui.bash'
fake.write_text('''#!/usr/bin/env python3
import json, os, pathlib, shlex, sys
board=os.environ['TEST_BOARD']
values={'TARGET_PRODUCT': os.environ.get('TARGET_PRODUCT',''),
        'TARGET_BUILD_VARIANT': os.environ.get('TARGET_BUILD_VARIANT',''),
        'PLATFORM_SDK_VERSION': os.environ.get('TEST_SDK','28'),
        'TARGET_DEVICE':board,'TARGET_ARCH':'arm64','OUT_DIR':os.environ['OUT_DIR'],
        'PRODUCT_OUT':os.environ['OUT_DIR']+'/target/product/'+board,
        'HOST_OUT':os.environ['OUT_DIR']+'/host/linux-x86',
        'ANDROID_JAVA_HOME':'/usr','ANDROID_JAVA_TOOLCHAIN':'/usr/bin'}
args=sys.argv[1:]
if args[0]=='--dumpvar-mode':
    if args[-1]=='TARGET_DEVICE' and os.environ.get('TEST_UNKNOWN_PRODUCT')=='1':
        print('SYNTHETIC: unknown product',file=sys.stderr); sys.exit(42)
    print(values.get(args[-1],''))
elif args[0]=='--dumpvars-mode':
    options=dict(arg[2:].split('=',1) for arg in args[1:])
    for option,prefix in [('vars','var-prefix'),('abs-vars','abs-var-prefix')]:
        for name in options[option].split():
            print(options[prefix]+name+'='+shlex.quote(values.get(name,'')))
elif args==['--make-mode','-j2','nothing']:
    assert values['TARGET_PRODUCT']=='lineage_'+board+'_stockgraph'
    assert values['TARGET_BUILD_VARIANT']=='userdebug'
    assert os.environ['FORGE_OFFLINE_SOURCE_SNAPSHOT']=='1'
    assert not os.environ.get('ALLOW_MISSING_DEPENDENCIES')
    assert os.environ['OUT_DIR']=='/workspace/scratch/out'
    try: pathlib.Path('/workspace/src/forbidden-write').write_text('bad')
    except OSError as error:
        assert error.errno==30, error
    else: raise AssertionError('source was writable')
    pathlib.Path('/workspace/scratch/synthetic-graph.json').write_text(json.dumps(values))
    sys.exit(int(os.environ.get('TEST_GRAPH_STATUS','0')))
else:
    print('unexpected synthetic backend args',args,file=sys.stderr); sys.exit(88)
''')
fake.chmod(0o755)
(SRC / 'device/meizu').mkdir(parents=True)
(SRC / 'vendor/meizu').mkdir(parents=True)
(SRC / '.remeizu').mkdir()
for board in ('m3s','u10','u20'):
    (SRC / 'device/meizu' / board).mkdir()
    (SRC / 'vendor/meizu' / board).mkdir()
    (SRC / '.remeizu' / (board+'-tools') / 'tools').mkdir(parents=True)
    (SRC / '.remeizu' / (board+'-tools') / 'planning').mkdir()
BIN = ROOT / 'bin'
BIN.mkdir()
(BIN / 'curl').write_text('#!/bin/sh\necho CURL_INVOKED >> /workspace/scratch/curl.log\nexit 86\n')
(BIN / 'curl').chmod(0o755)
cases = [('m3s','success',{}), ('u10','success',{}), ('u20','success',{}),
         ('m3s','graph-failed',{'TEST_GRAPH_STATUS':'47'}),
         ('m3s','sdk-mismatch',{'TEST_SDK':'27'}),
         ('m3s','unknown-product',{'TEST_UNKNOWN_PRODUCT':'1'})]
result_rows = []
for board, label, overrides in cases:
    case = ROOT / (board+'-'+label)
    case.mkdir()
    (case / 'scratch').mkdir()
    (case / 'out').mkdir()
    rev = 'r3' if board == 'u20' else 'r2'
    command=['bwrap','--unshare-user','--unshare-pid','--unshare-net','--die-with-parent',
             '--tmpfs','/','--ro-bind','/usr','/usr','--ro-bind','/bin','/bin',
             '--ro-bind','/lib','/lib','--ro-bind','/lib64','/lib64','--ro-bind','/etc','/etc',
             '--proc','/proc','--dev','/dev','--tmpfs','/tmp','--tmpfs','/workspace',
             '--ro-bind',str(SRC),'/workspace/src',
             '--ro-bind',str(REPO / 'device/meizu' / board),'/workspace/src/device/meizu/'+board,
             '--ro-bind',str(REPO / 'tools'),'/workspace/src/.remeizu/'+board+'-tools/tools',
             '--ro-bind',str(REPO / 'planning'),'/workspace/src/.remeizu/'+board+'-tools/planning',
             '--ro-bind',str(args.private_root / (board+'-vendor-stockgraph-'+rev)),
             '/workspace/src/vendor/meizu/'+board,
             '--ro-bind',str(BIN),'/harness-bin',
             '--bind',str(case / 'scratch'),'/workspace/scratch','--bind',str(case / 'out'),'/workspace/out',
             '--clearenv','--setenv','PATH','/harness-bin:/usr/bin:/bin',
             '--setenv','OUT_DIR','/workspace/scratch/out','--setenv','TEST_BOARD',board,
             '--setenv','ALLOW_MISSING_DEPENDENCIES','true','--setenv','PYTHONDONTWRITEBYTECODE','1',
             '--setenv','FORGE_OFFLINE_SOURCE_SNAPSHOT','1','--setenv','TERM','dumb']
    for key,value in overrides.items():
        command += ['--setenv',key,value]
    command += ['--chdir','/workspace/src','--','bash',
                '/workspace/src/.remeizu/'+board+'-tools/tools/run_'+board+'_stockgraph.sh',
                '/workspace/src','/workspace/src/.remeizu/'+board+'-tools','userdebug']
    result=subprocess.run(command,text=True,capture_output=True,timeout=30)
    (case/'stdout.log').write_text(result.stdout)
    (case/'stderr.log').write_text(result.stderr)
    published=sorted(p.name for p in (case/'out').iterdir())
    row={'board':board,'case':label,'status':result.returncode,'artifacts':published,
         'curl_called':(case/'scratch/curl.log').exists(),
         'synthetic_backend_reached':(case/'scratch/synthetic-graph.json').exists()}
    assert not row['curl_called'], row
    if label=='success':
        assert result.returncode==0 and published==sorted([board+'-stockgraph-evidence.json','product-config.txt']), (row,result.stderr,result.stdout)
        assert row['synthetic_backend_reached']
    else:
        assert result.returncode!=0 and not published, (row,result.stderr,result.stdout)
    result_rows.append(row)
    print(json.dumps(row),flush=True)
report={'schema':'remeizu.runner-shell-ro-harness.v1','real_platform_shell_files_before_sha256':before,
        'source_mount':'/workspace/src (read-only bind)','OUT_DIR':'/workspace/scratch/out',
        'publication_root':'/workspace/out','network_namespace':'isolated',
        'backend':'synthetic Soong variable/exit fixture; no Android graph or build',
        'results':result_rows,'runtime_verified':False}
(ROOT/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print('REPORT',ROOT/'report.json')
