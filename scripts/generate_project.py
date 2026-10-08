"""Generate a dependency-free, conventional Xcode project; run after adding files."""
from pathlib import Path
import hashlib, json, plistlib

ROOT = Path(__file__).resolve().parents[1]
def uid(s): return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def q(s): return json.dumps(str(s), ensure_ascii=False)
objects = {}
def obj(key, body):
    objects[uid(key)] = '{ ' + body + ' };'
    return uid(key)
def arr(ids): return '(' + ', '.join(ids) + (',' if ids else '') + ')'
app_files = sorted((ROOT/'App').rglob('*.swift')) + sorted((ROOT/'Core').rglob('*.swift'))
test_files = sorted((ROOT/'Tests').rglob('*.swift'))
resources = sorted((ROOT/'App/Resources').rglob('*')) if (ROOT/'App/Resources').exists() else []
resources = [p for p in resources if (p.is_file() and not any(parent.suffix == '.lproj' for parent in p.parents)) or p.suffix == '.lproj']
if (ROOT/'App/Assets.xcassets').exists(): resources.append(ROOT/'App/Assets.xcassets')
refs, app_builds, test_builds, res_builds = [], [], [], []
for p in app_files + test_files + resources:
    rel = p.relative_to(ROOT).as_posix()
    typ = 'sourcecode.swift' if p.suffix == '.swift' else 'folder.assetcatalog' if p.suffix == '.xcassets' else 'folder' if p.suffix == '.lproj' else 'text'
    r = obj('file:'+rel, f'isa = PBXFileReference; lastKnownFileType = {typ}; path = {q(rel)}; sourceTree = SOURCE_ROOT;')
    refs.append(r)
    b = obj('build:'+rel, f'isa = PBXBuildFile; fileRef = {r};')
    (app_builds if p in app_files else test_builds if p in test_files else res_builds).append(b)
products = []
for target, ext, typ in [('TravelMemory','app','wrapper.application'),('TravelMemoryTests','xctest','wrapper.cfbundle')]:
    products.append(obj('product:'+target, f'isa = PBXFileReference; explicitFileType = {typ}; path = {target}.{ext}; sourceTree = BUILT_PRODUCTS_DIR;'))
pg = obj('products', 'isa = PBXGroup; name = Products; children = '+arr(products)+'; sourceTree = "<group>";')
obj('main', 'isa = PBXGroup; children = '+arr(refs+[pg])+'; sourceTree = "<group>";')
for key, isa, files in [('sources','PBXSourcesBuildPhase',app_builds),('testSources','PBXSourcesBuildPhase',test_builds),('resources','PBXResourcesBuildPhase',res_builds),('frameworks','PBXFrameworksBuildPhase',[])]:
    obj(key, f'isa = {isa}; buildActionMask = 2147483647; files = {arr(files)}; runOnlyForDeploymentPostprocessing = 0;')
common = {'IPHONEOS_DEPLOYMENT_TARGET':'17.0','SDKROOT':'iphoneos','SWIFT_VERSION':'5.0','SWIFT_STRICT_CONCURRENCY':'complete','CLANG_ENABLE_MODULES':'YES','TARGETED_DEVICE_FAMILY':'1','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','SUPPORTS_MACCATALYST':'NO','CODE_SIGN_STYLE':'Automatic'}
for scope in ['project','app','tests']:
    configs=[]
    for mode in ['Debug','Release']:
        settings=dict(common)
        settings.update({'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if mode=='Debug' else '-O','DEBUG_INFORMATION_FORMAT':'dwarf' if mode=='Debug' else 'dwarf-with-dsym'})
        if mode=='Debug': settings.update({'SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG','ENABLE_TESTABILITY':'YES'})
        if scope=='app': settings.update({'PRODUCT_NAME':'TravelMemory','PRODUCT_BUNDLE_IDENTIFIER':'local.personal.travelmemory','INFOPLIST_FILE':'App/Info.plist','GENERATE_INFOPLIST_FILE':'NO','MARKETING_VERSION':'2.0','CURRENT_PROJECT_VERSION':'1','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks'})
        if scope=='app' and (ROOT/'App/Assets.xcassets').exists(): settings['ASSETCATALOG_COMPILER_APPICON_NAME']='AppIcon'
        if scope=='tests': settings.update({'PRODUCT_NAME':'TravelMemoryTests','PRODUCT_BUNDLE_IDENTIFIER':'local.personal.travelmemory.tests','GENERATE_INFOPLIST_FILE':'YES','TEST_HOST':'$(BUILT_PRODUCTS_DIR)/TravelMemory.app/TravelMemory','BUNDLE_LOADER':'$(TEST_HOST)'})
        configs.append(obj(scope+mode, 'isa = XCBuildConfiguration; name = '+mode+'; buildSettings = { '+ ' '.join(k+' = '+q(v)+';' for k,v in settings.items())+' };'))
    obj(scope+'config', 'isa = XCConfigurationList; buildConfigurations = '+arr(configs)+'; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
obj('proxy', f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("app")}; remoteInfo = TravelMemory;')
obj('dependency', f'isa = PBXTargetDependency; target = {uid("app")}; targetProxy = {uid("proxy")};')
for key,name,phases,product,kind,deps in [('app','TravelMemory',['sources','frameworks','resources'],products[0],'application',[]),('tests','TravelMemoryTests',['testSources'],products[1],'bundle.unit-test',[uid('dependency')])]:
    obj(key, f'isa = PBXNativeTarget; buildConfigurationList = {uid(key+"config")}; buildPhases = {arr([uid(p) for p in phases])}; buildRules = (); dependencies = {arr(deps)}; name = {name}; productName = {name}; productReference = {product}; productType = "com.apple.product-type.{kind}";')
obj('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; }}; buildConfigurationList = {uid("projectconfig")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = "zh-Hans"; hasScannedForEncodings = 0; knownRegions = ("zh-Hans", en, Base); mainGroup = {uid("main")}; productRefGroup = {pg}; projectDirPath = ""; projectRoot = ""; targets = {arr([uid("app"),uid("tests")])};')
project = ROOT/'TravelMemory.xcodeproj'; project.mkdir(exist_ok=True)
(project/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(k+' = '+v for k,v in objects.items())+'\n}; rootObject = '+uid('project')+'; }\n', encoding='utf-8')
scheme = project/'xcshareddata/xcschemes'; scheme.mkdir(parents=True,exist_ok=True)
ref=lambda target: f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(target)}" BuildableName="{"TravelMemory.app" if target=="app" else "TravelMemoryTests.xctest"}" BlueprintName="{"TravelMemory" if target=="app" else "TravelMemoryTests"}" ReferencedContainer="container:TravelMemory.xcodeproj"/>'
(scheme/'TravelMemory.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref('app')}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref('tests')}</TestableReference></Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('app')}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('app')}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>''',encoding='utf-8')
print(f'Project generated: {len(app_files)} app/core sources, {len(test_files)} tests, {len(resources)} resources')
