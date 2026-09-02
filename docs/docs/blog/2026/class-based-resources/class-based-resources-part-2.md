# From Script-Based to Class-Based, Part 2: Making the Module Fast Again

<img src="../../../images/FabienTschanz.jpg" style="width:75px;border-radius:50%;border:3px solid black;float:left;" />
<div style="position:inherit;padding-top:15px;"><span style="float:left;padding-left:15px;"><b>by <a href="https://www.linkedin.com/in/fabien-tschanz">Fabien Tschanz</a><br />
October 7th, 2026</b></span></div>

<br/>
<br/>

## Introduction

[Part 1](./class-based-resources.md) ended on a slightly uncomfortable note. We had a module that was correct in every way we could test, but it was slower than the one it replaced, and not in a way you could wave off. Importing the module took three seconds longer, discovering resources took longer, parsing an export back into objects took longer, and comparing a tenant against a blueprint took longer too. Nothing dramatic on its own, but it was there every single day for every single user, and that is not what you want from a release you spent two years on.

So this part is the story of getting those seconds back, one path at a time, through import, discovery, DSCParser, the base class, the export engine and the comparison engine. The method was always the same one: measure, find the floor, throw every idea we had at it, keep what moved the needle, and be honest about what did not. I am going to show you a lot of numbers along the way, and I am also going to show you the ideas that failed, since those taught us at least as much as the ones that worked.

A word on those numbers before we start. Unless a table says otherwise, all of them come from my laptop, a Surface Laptop 6 for Business with an Intel Core Ultra 7 165H and 32 GB of RAM, running PowerShell 7.6.5 and Windows PowerShell 5.1. Every sample ran in a fresh process with exactly one Microsoft365DSC version on `PSModulePath`, staged through a directory junction. That last detail sounds pedantic, but it is not: Two installed versions of a module this size will quietly hand you measurements of whichever one the engine happened to resolve, and we learned that the hard way. [Part 3](./class-based-resources-part-3.md) has an estimate of what these numbers look like on a CI runner.

## Table of Contents

1. [Where the import time actually goes](#where-the-import-time-actually-goes)
2. [The bucket sweep that changed nothing](#the-bucket-sweep-that-changed-nothing)
3. [Three layouts we evaluated](#three-layouts-we-evaluated)
4. [The FunctionsToExport trap, revisited](#the-functionstoexport-trap-revisited)
5. [DSCParser: parsing exports without paying for discovery](#dscparser-parsing-exports-without-paying-for-discovery)
6. [The base class under a profiler](#the-base-class-under-a-profiler)
7. [The export engine, workload by workload](#the-export-engine-workload-by-workload)
8. [The compiled comparison engine](#the-compiled-comparison-engine)
9. [The small things that add up](#the-small-things-that-add-up)
10. [How to measure without lying to yourself](#how-to-measure-without-lying-to-yourself)
11. [Where part 2 leaves us](#where-part-2-leaves-us)

## Where the import time actually goes

Part 1 measured the spike layout at 6.95 seconds, and that number came with an asterisk: The spike used stub method bodies. The shipped module has the real thing, 531 resource classes with their full `Get`, `Set` and `Test` implementations, 469 complex-type classes and 28 helper modules, 54 nested modules in total. So a couple of weeks ago I measured it again, importing the module by name in a fresh process, side by side with the last script-based release:

| Layout | Import, PowerShell 7 / Windows PowerShell | Second runspace, same process | Working set | `Get-Module -ListAvailable` |
| --- | --- | --- | --- | --- |
| 1.26.826.1, script-based | 1.67 s / 1.97 s | 0.97 s / 1.10 s | 178 MB | 0.12 s / 0.10 s |
| Class-based, 16 parts and 8 type buckets | 4.96 s / 5.67 s | 2.87 s / 3.62 s | 386 MB | 1.13 s / 0.74 s |

Three seconds worse on the first import stings, but it is the second column that really hurt. PowerShell's class type cache does not survive a runspace, which means a second runspace in the same process pays for all of that type creation again, and both the LCM and the PowerShell 7 relay from part 1 open a runspace per call. Two to three seconds, per runspace, forever. A freshly copied or freshly installed module is worse still at 8.7 to 11.7 seconds on PowerShell 7, since the new write times invalidate the module analysis cache and `Import-Module` has to re-analyze all 54 nested modules from scratch.

So where do the five seconds actually go? We took the built `Classes/` folder apart and imported scratch variants of the very same files, one after the other, on PowerShell 7:

| Variant | Total | What it tells you |
| --- | --- | --- |
| As built | 9.1 s | |
| Every method body replaced by a stub | 7.3 s | bodies are parse cost, 1.8 s on PowerShell 7 and 5.7 s on Windows PowerShell |
| `[ValidateSet]` attributes removed | 7.3 s | no effect at all |
| Only `Get`, `Set` and `Test` kept | 4.7 s | the hidden helper methods cost 2.7 s |
| Properties only, no methods | 3.8 s | the type creation floor, about 5.5 ms per resource class |

Once you see the mechanism, it is almost obvious. PowerShell creates class types when it *compiles* a file, before a single statement in that file runs, and `Import-Module` compiles every `NestedModules` entry it finds. DSC's class discovery only looks at `RootModule` and one level of `NestedModules`, so whatever we want DSC to find gets compiled eagerly, no exceptions, and the 3.8-second floor is simply the price of a thousand classes existing at all. Method count matters at roughly half a millisecond per method, while attribute count does not matter in the slightest. And here is the part that made me wince a little: the helper methods we so carefully moved into the classes in part 1, for cleanliness and for `$this`, cost more at import time than the actual resource bodies do.

## The bucket sweep that changed nothing

The hypothesis we carried over from the spike was that bucket size is the lever, so fewer classes per file should mean less of that superlinear type creation and a faster import. It was a reasonable hypothesis and we treated it seriously. `Build-Microsoft365DSC.ps1` gained a `-BalanceBy Count|Bytes` switch, `Measure-M365DSCLoadPerformance.ps1` gained axes for the part count, the type bucket count, a second runspace and `using module`, and we swept the real tree with eight, sixteen and thirty-two parts times four, eight and sixteen type buckets, balanced by class count and again by bytes, medians of three for each.

Eighteen layouts later, the import sat between 4.2 and 5.0 seconds on PowerShell 7 and 5.1 to 6.5 on Windows PowerShell, the second runspace between 3.1 and 4.1, `using module` on the manifest between 5.1 and 6.8, and a parse-only pass between 1.7 and 2.4. Every single layout lands inside the noise band of every other one. The spike's cube curve is real when you put a thousand classes into one file, but the moment you spread them across more than a handful of files the curve goes flat, and bucketing simply stops being a lever. The defaults stayed at 16 and 8, and the sweep tooling stayed in the repository so that nobody ever has to take this paragraph on faith.

## Three layouts we evaluated

If the floor is "every class DSC can discover gets compiled at import", the only way underneath it is to give DSC something cheaper to discover than the classes themselves. We built three candidates, staged each one as a complete module, and drove them through the real engines.

**D1, a MOF facade with lazy classes.** DSC sees 531 MOF-based resources, each with a generated `.schema.mof` and a tiny script shim whose `Get-TargetResource` imports the part holding the real class on first use and then forwards the call. The classes are all still there, but nothing gets discovered eagerly.

**D2, a class facade with lazy implementation.** DSC sees 531 property-only classes with no method bodies, whose `Get`, `Set` and `Test` import the implementation part on first use and relay to it.

**D3, keep the eager layout and cut its cost**, by moving the helper methods and bodies out of the 531 classes.

| | Current | D1 MOF facade | D2 class facade | D3 cut cost |
| --- | --- | --- | --- | --- |
| Import, PowerShell 7 / Windows PowerShell | 4.96 s / 5.67 s | **1.29 s / 1.54 s** | 2.44 s / 3.38 s | about 4 to 5 s |
| Per additional runspace | 2.87 s / 3.62 s | 0.46 s / 0.52 s, plus 0.1 to 0.2 s per part touched | 1.79 s / 2.21 s, plus 0.09 s per part | as import |
| First resource instance | 0.15 s after the import | 0.67 s / 0.88 s | 0.33 s / 0.40 s | as current |
| Discovery through the DSC engines | 18 to 20 s | 7 s | 6 to 7 s | 18 to 20 s |
| Working set | 386 MB | 178 MB | 275 MB | about 386 MB |
| Compile of the 726-instance export, classic path | 55 s | 13.3 s | as current | as current |

Look at that D1 column. From the engine's point of view it *is* the script-based module again, importing in 1.29 seconds against the 1.67 of the old release, with the same working set, and even the classic compile path gets most of its speed back since the engine reads MOF files instead of creating types. D2 halves the current import. Both of them work, and I will admit that seeing D1 come in under the old baseline was a genuinely happy moment after weeks of flat sweeps. Building them also taught us one lesson worth writing down for anyone attempting the same: the lazy import must run with `Import-Module -Global`. Importing a part from inside the shared base module's scope made the engine walk `GetExportedTypeDefinitions` recursively until the stack overflowed, and a `.psd1` resource map refused to load since the engine rejects "dynamic expressions" in data files. The map became JSON, the import became global, and both facades came to life.

And then we shipped neither of them.

I know. The decision belongs to [part 3](./class-based-resources-part-3.md#dscv3-what-323-makes-of-the-module), where the deciding factor lives, and that factor is DSCv3. Its PowerShell adapter drives class-based resources only, MOF resources run through the Windows PowerShell adapter alone, and as of today the adapter cannot even name a class that lives in a nested file. D1 buys the import time back and slams the DSCv3 door shut, while D2 keeps the door open but shares the nested-file naming problem with the current layout until the adapter is fixed. So the layout stays as it is, the measurements and the generators stay in the repository, and the moment the adapter changes we will know exactly what each option costs. That is not the ending I wanted for this section, but it is the honest one.

## The FunctionsToExport trap, revisited

Part 1 recorded the absurd fact that an explicit `FunctionsToExport` list makes every class-based resource vanish from `Get-DscResource`, and back then we left the key commented out and moved on with our developer lives. In September, with `Get-Module -ListAvailable` showing up in every profile at 1.1 seconds per call, I went back to it with the engine source open. "Leave the key out" is the exact opposite of what every module author is taught, and I wanted to understand why the engine punishes you for doing the right thing.

The mechanism lives in `ModuleCmdletBase`. When a manifest has explicit `FunctionsToExport`, `CmdletsToExport` and `AliasesToExport` with no wildcards, `Get-Module -ListAvailable` takes an early return that builds the module info from the manifest alone without ever touching the nested modules, and that is what makes it fast. Unfortunately, the same early return happens *before* the engine records `DscResourcesToExport` on the module info, and every DSC engine we have, the inbox 1.1 module, the gallery 2.0.7 module, our fork and DSCParser's `Get-DscResourceV2`, checks `ExportedDscResources.Count -gt 0` before it looks any further. Zero resources, no error, fast and very much useless.

| Manifest variant | `Get-Module -ListAvailable`, PS 7 / WPS | `ExportedDscResources` | `Import-Module`, cold analysis cache | `Get-DscResourceV2` | Fast host / 2.0.7 / inbox 1.1 |
| --- | --- | --- | --- | --- | --- |
| key absent (shipped) | 1.27 s / 0.80 s | 531 | 8.7 s / 5.8 s | 531 in 4.0 s | 999 / 999 / 531 |
| `'*'` | 1.27 s / 0.87 s | 531 | 8.6 s / 6.0 s | 531 in 3.3 s | 999 / 999 / 531 |
| explicit list | 1.84 s / 0.08 s | 0 on PS 7, 531 on WPS | 4.6 s / 5.9 s | **0** | **0 / 0 / 0** |
| explicit list plus `AliasesToExport = '*'` | 0.07 s / 0.07 s | 531 | 4.4 s / 4.9 s | **0** | **0 / 0 / 0** |

The last row is the one I had real hopes for: keep the fast early return for functions and cmdlets, poke a wildcard into the alias list, and force the engine to look at the module after all. `ExportedDscResources` does come back, and yet every DSC engine still returns zero, since they discover through a different code path that the early return has already starved. So the key stays absent, at a price of about 1.2 seconds per `Get-Module -ListAvailable` and about 4 seconds per `Import-Module` on a cold analysis cache. What we could do, we did. Every consumer that can avoid `Get-Module -ListAvailable` now does that, with the fast host scanning `PSModulePath` for the manifest itself and DSCParser caching the module catalog once per process.

## DSCParser: parsing exports without paying for discovery

DSCParser is the module that turns a `.ps1` configuration back into objects. Microsoft365DSC leans on it for `Compare-M365DSCConfigurations`, for the blueprint assertion, for the delta report and for the examples QA gate, so every millisecond it costs multiplies through everything that reads an export. It had been rewritten in C# in March 2026 for correctness and speed, and then it hit the same wall as everything else the day the resources became classes. Three releases in August and September of 2026 got it back on its feet, and each one is a small lesson in where PowerShell hides its costs.

**3.1.0.0, the refactor pass (August 7).** Reading old code with a profiler next to it is a humbling experience. A type-name conversion looped over every discovered resource name for every property and then returned the same string on both branches. There were seven copies of the same reflection lookup into the engine's `DscClassCache`, three of them inside per-resource loops, a property list allocated fresh on every read, one `Get-Module -ListAvailable` round trip per module, and a writer that re-split and re-indented its output once per nesting level. With all of that gone and one cached reflection helper in its place, writing a resource with 25 nested instances five levels deep went from 200 to 54 milliseconds, byte-identical, and parsing a tiny configuration 25 times dropped from 3.0 to 1.7 seconds.

**3.1.0.0, keyword pre-cache (August 9).** The same discovery that part 3 describes for the compiler hits DSCParser on every parse, since PowerShell rebuilds the DSC keyword registration from scratch each time it parses a configuration containing `Import-DscResource`, probing the file system per resource as it goes. DSCParser now keeps that registration alive for the whole process, removes the `Import-DscResource` statements from the text before parsing, and re-parses them separately under a placeholder command name to learn which modules to load. It also imports only the class resources the manifest lists and skips the MOF keyword import for anything without a `.schema.mof`. If that sounds like the fast host from part 3, you are right. It is the same idea, discovered from the other end at roughly the same time.

**3.1.0.1, the stale cache (August 10).** Two days later the pre-cache blew up in production. After a second MOF compile in the same process, `Get-DscResourceV2` returned zero resources where 3.0.0.5 had returned 556, and `ConvertTo-DSCObject` threw "No DSC resources loaded". The engine's `DscClassCache` and the keyword table are `[ThreadStatic]`, every compile wipes them, and the registry had trusted its own bookkeeping. The fix probes a sentinel keyword (`OMI_ConfigurationDocument`) before trusting the cache and re-imports once on a mismatch, restores the default keywords from a snapshot rather than calling the engine's `LoadDefaultCimKeywords` (which drops every module keyword along the way, 1,058 down to 32), and clears the keyword table after every operation, since leftover entries made the engine skip its own reset and broke compiling exports afterwards. Windows PowerShell reinitializes the class cache on every configuration parse, so there every parse pays the import again, and discovery went from 17 silently degraded resources to 557. The probe costs 100 to 150 milliseconds per hot parse, which is cheap insurance.

**3.1.0.4, caching and first load (September 2).** This is the release Microsoft365DSC pins, measured against 3.1.0.3 on the class-based 1.26.1007.1 build, fresh process per scenario, three repetitions per file:

| Operation | Before | After |
| --- | --- | --- |
| `Get-DscResourceV2 -Module Microsoft365DSC`, cold | 6.0 to 8.9 s, 1,038 MB | 4.0 to 4.5 s, 974 MB |
| `Get-DscResourceV2 -Module Microsoft365DSC`, warm | 2.9 to 3.1 s, 554 MB | **23 to 44 ms, 4.8 MB** |
| Full-machine discovery, 567 resources, warm | 2.7 s, 578 MB | 117 ms, 16 MB |
| `ConvertTo-DSCObject`, one resource, 1.9 KB | 155 to 176 ms, 98 MB | **2.4 to 2.7 ms, 0.3 MB** |
| `ConvertTo-DSCObject`, Teams, 102 instances, 157 KB | 173 to 195 ms | 15 to 16 ms |
| `ConvertTo-DSCObject`, Azure AD, 231 instances, 363 KB | 234 to 239 ms | 70 to 77 ms |
| `ConvertTo-DSCObject`, Exchange Online, 726 instances, 517 KB | 272 to 283 ms, 130 MB | 92 to 105 ms, 32 MB |
| `ConvertTo-DSCObject`, Security and Compliance, 612 instances, 650 KB | 306 to 311 ms | 175 to 202 ms |
| `ConvertTo-DSCObject`, Intune, 251 instances, 1.3 MB | 498 to 835 ms, 188 MB | 339 to 382 ms, 90 MB |

Sixty times faster on a warm discovery. Where did that come from? Six places, and none of them exotic. The engine's `GetCachedKeywords()` rebuilds every keyword from its CIM class on each call, 70 to 160 milliseconds and 31 MB a pop, and DSCParser was calling it three times per conversion, so now there is one snapshot per class-cache change. `PowerShell.Create()` was opening a brand new runspace for every `Get-Module` and `Get-Command`, with three duplicate `Get-Module -ListAvailable` sites on top, and now it is a nested pipeline on the caller's runspace backed by a process-wide module catalog. `Get-Command -CommandType Configuration` in a fresh runspace forced a full `PSModulePath` analysis, 6.8 seconds on a cold analysis cache, and a cold analysis cache is exactly what every CI job has; `-ListImported` on the caller's runspace takes 4 to 30 milliseconds instead. A type-name conversion ran about 40,000 times per discovery for about 30 distinct inputs and got memoized. The object mapper re-copied all 560 resources through `dynamic` on every conversion and now passes them straight through. And `ConvertTo-DSCObject` without an explicit resource list discovers only the modules the configuration imports rather than the whole machine. We checked output equivalence on all eight benchmark exports by object hash and by rendered text hash, and as a bonus the resource cache test file went from 14 seconds to half a second.

Two ideas were tried and dropped along the way. Skipping nested modules without resources saved 0.24 seconds and needed private engine reflection to do it, and a reverse class-to-file index saved 28 milliseconds for 1,031 keywords. Neither earned its complexity. What remains on a cold call is the engine itself, `ImportClassResourcesFromModule` at 2.15 seconds and 543 MB for 1,195 classes, which is the type creation floor from the first section seen from another module.

## The base class under a profiler

Every resource inherits from `M365DSCResourceBase`, which means anything that base class does per property happens half a million times in a full export. In late August we put a real profiler on an Intune export, and it found three things in the base class that nobody, myself included, would have guessed from reading the code.

**One `Update-TypeData` per property.** The base class registers type data for every DSC property of every class so that PowerShell displays and serializes them the way we want, and it did that with one `Update-TypeData` call per property: 4,740 calls at 1.1 milliseconds each, 5.2 seconds and 1.18 GB of allocations in the profiled export. One call per *type* with the complete member set does the identical job. Constructing a 300-property resource for the first time dropped from 331 to 347 milliseconds down to 46 to 86, and constructing every one of the 531 resources once went from 19.1 seconds and 1,988 MB to 14.3 seconds and 518 MB.

**`ToHashtable` walked the schema every time.** The flattening that part 1 describes for the PowerShell 5.1 relay, which the export engine uses as well, rebuilt its property metadata on every call. With the metadata captured once per type and a snapshot per instance, 100 calls went from 3,076 milliseconds to 25.

**`FromHashtable` went through the extended type system for every assignment.** Resolving the property once and writing the value through the class's own setter cut the Intune export from 138.5 to 96.1 seconds in an interleaved A/B run, minus 31 percent, for a change we had estimated at 3.5 seconds. I want to dwell on that for a moment. The estimate was wrong in our favor, which is nice, but a later micro-benchmark then showed that the two setters had become equivalent, so the mechanism we thought we were fixing was not the whole story. The measurement stands while the explanation was incomplete, and that is exactly why I have stopped trusting estimates in this domain and only trust the paired run.

Just as valuable is what the profiler refuted. Caching property getters as delegates turned out to be *slower* than a plain `PropertyInfo.GetValue` (0.022 versus 0.016 milliseconds), and an `-as` type guard was slower than the cast it replaced. The per-resource `Get()` bodies have no hot spot at all, with 8.4 seconds of CPU spread across 9,668 lines and the single most expensive line at 87 milliseconds. Their cost simply tracks schema width, about 1.2 to 1.3 milliseconds per generated property per instance, and only a change to the generator could move that, so we deferred it. Fifteen resources with zero instances in the tenant still cost 110 milliseconds each for the connection and the empty query, and honestly, that is fine.

## The export engine, workload by workload

The July [performance post](../performance-improvements/performance-improvements.md) covered pre-fetching, parallel export and the C# caches, measured on an Azure DevOps runner. After the conversion we took each workload apart again on the laptop, this time with one uncompromising acceptance criterion: an export before and after a change has to produce the same file, byte for byte, or the change is a bug until proven otherwise. These numbers are not comparable to July's CI numbers, since the tenant, the machine and the versions all differ, but the before and the after in every row below were taken on the same day, on the same box, against the same tenant.

**Intune.** The baseline export took 284 seconds as a mean of three, made 466 Graph round trips, allocated 4.7 GB and peaked at 1.1 GB of working set for 143 resources and 218 blocks. Roughly 135 seconds of that was Graph, 25 was startup, and 70 seconds we could not attribute to anything at all until the profiler ran. The fixes, in order of impact, read like a checklist of things that were each individually reasonable and collectively expensive. A shared collection cache with `$expand=assignments` turned the 54 list calls the resources were making into 3 and dropped the total from 466 to 149 requests. A group cache took 128 `Get-MgGroup` calls down to 10. An Azure fail-fast for tenants without the Azure workload replaced two 10-second attempts with one that takes 2.7. Authentication-method detection now reads the schema cache instead of parsing 10 MB of class files with the AST, which is 100 milliseconds instead of 2.6 to 5.9 seconds and 450 MB less memory. ReverseDSC 3.0.0.0 rendered faster, a dependency check that used to take 2,379 milliseconds now validates in 107, and a lazily built resource dictionary brought startup from 2,350 milliseconds down to 17.6. After the first batch the export measured 109 seconds mean over seven clean runs, and after the base-class fixes from the previous section it sat at 72 to 92 seconds, 218 blocks, 814,605 bytes, identical to the byte. One finding surprised the people who had asked for it most: `-Parallel` on this tenant is *not* faster, at 93 seconds and 5.2 GB against 72 to 92 seconds and 2.2 GB sequential, since each runspace pays the 4 to 9 second import first. That is the part 1 cost wearing a different hat.

**Azure AD.** The full export went from 376 to 265 seconds on the best clean run, and from 1,498 requests to 589. `AADApplication` alone went from 246 requests to 35 and from 45.8 to 15.5 seconds, `AADRoleManagementPolicyRule` from 148 requests to 4, and `AADUser` from 136 to 18. The output actually *grew* from 5.8 to 6.9 MB, since resources that had silently exported nothing now export properly, 515 service principals instead of 0. One regression on the way became my favorite argument for tenant-level byte diffs. A wrapper change truncated `-All` to the first page on PowerShell 7.6, so 515 service principals became 100 and 132 users became 100, while 5,600 unit tests stayed a beautiful, useless green. The byte diff caught it on the very first run. We also built a cost model for a tenant with 80,000 applications, which is not hypothetical for some of our users: 320,940 requests and 10.9 hours of HTTP before, about 18,800 requests and 5.5 hours after, 4 GB of RAM not survivable, 8 GB fine.

**Exchange Online and Security and Compliance.** The full Exchange Online export went from 1,162.6 to 396.2 seconds, minus 66 percent, and Security and Compliance from 424.3 to 198.1, minus 53 percent, both byte-identical. Three resources were the bulk of it, and all three turned out to be logic errors rather than slow APIs, which is both embarrassing and encouraging. `EXOManagementRoleEntry` compared a composed `Identity\Name` against the bare identity in `Get()`, never matched, and refetched all 3,198 instances one by one, so 720 seconds became 23.5. `SCRoleGroupMember` called `Get-RoleGroupMember` for 75 of 79 groups that were empty, and 158 seconds became 6.4. `SCSensitivityLabel` compared a parent GUID against a parent name, and 77 seconds became 4.7. Below that, the Exchange cmdlets themselves are the floor. A `Get-Mailbox` object retains 86 KB, so 50,000 mailboxes would be 4.3 GB against 76 MB for a narrow projection, and the per-mailbox cmdlets have no bulk form, which is why the collection cache from the July post now also fronts `Get-Mailbox` and `Get-User` for the eight resources that call them.

**Teams.** Full export 306 seconds, 64 resources, 0 failures. The top three per-user resources make up 65 percent of the time and take 380 to 560 milliseconds per user, with `Identity` mandatory and no bulk form in sight. There is nothing to implement there, and knowing that with certainty was worth the measurement on its own.

## The compiled comparison engine

The July post explained why the drift comparison lives in C#. Building the 531 resource definitions for it had already gone from 3,151 to 885 milliseconds in August when the per-property scriptblock loop moved into `CacheManager`, with all 14,378 property rows byte-identical. A little war story from that port: a "faithful" translation of `@($null)` produced a one-element null array where PowerShell had produced an empty one, and only the row diff caught it. With typed class instances on both sides of every comparison, the assembly got a second pass in September, and the numbers were larger than I expected from code that was already compiled:

| Stage | Before | After |
| --- | --- | --- |
| `ResourceComparer`, per instance, Exchange Online export | 475 ms, 77 MB | 32 ms, 5 MB |
| `ConfigurationComparer`, Exchange Online export | 454 ms, 76 MB | 21 ms, 4 MB |
| `ConfigurationComparer`, Security and Compliance export | 1,117 ms, 103 MB | 87 to 108 ms, 13 MB |
| Garbage per compared pair | about 106 KB | about 5 KB |
| Intune Settings Catalog policy build, Windows 10 baseline | 19.6 ms | 9.3 ms |
| `SCSensitivityLabel` post-processing callback | 114 ms | 32 ms |

The techniques are the boring, effective kind, and I mean that as a compliment. The schema view of a resource type is computed once and kept in a `ConditionalWeakTable` keyed by the type, so it lives exactly as long as the type does and is never recomputed per instance. Pairing source and target instances used to be quadratic, every instance against every other instance, and it is structural now, keyed on the key properties. Drift records share one shape instead of allocating a fresh object graph per property, the converter caches its reflection per type, and the Intune settings helper memoizes resolved setting names. The Settings Catalog templates that every Intune settings policy resource resolves are cached per session, with a template that is not in the cache yet fetched once and kept. And the Security and Compliance resources finally treat `$null` and an empty collection as equal, so they stopped logging drift that was never there.

Two smaller fixes fell out of the same pass. `Set-M365DSCVerbosePreferenceInScope` stored a `SwitchParameter` where an `ActionPreference` belonged, which produced `SwitchParameter 'Verbose'` failures inside `Test()` on the class path. And the delta report used to instantiate every single resource class just to ask whether it had post-processing, where it now instantiates only the handful flagged `HasPostProcessing`.

## The small things that add up

- **`Get-Module -ListAvailable` is the tax of the missing export list.** Every consumer that can scan the manifest itself now does. If you write tooling around the module, prefer `Test-ModuleManifest` or `Import-PowerShellDataFile` on the manifest over `Get-Module -ListAvailable -Name Microsoft365DSC`, since on this module that is 64 milliseconds against 1.3 to 1.6 seconds and 400 MB.
- **Verbose output during import.** The helper modules used to chatter verbose messages while the nested modules loaded, which nobody notices until they run with `-Verbose` and wait for 54 modules to narrate themselves. Import is silent now, and the module's own verbose logging is scoped to the operation that asked for it.
- **Repeated Graph calls.** The telemetry engine resolves the directory roles of the signed-in identity once per session, but for an identity with *no* roles the empty result looked exactly like "not resolved yet", and the Graph call repeated on every telemetry event. A resolved flag instead of an empty check fixed it, and this is precisely the kind of thing the export profiles now make visible.
- **`+=` on arrays is not a hotspot any more.** PowerShell 7.5 grows an array in place, and the profile confirms it. Rewriting `$array += $item` to a generic list buys nothing on the editions we support and costs readability, so we stopped doing it.
- **Graph `$batch` responses arrive in arbitrary order.** The batch adapter that moved onto the Mgx module returns sub-responses in input order, which turned a nondeterministic `AllowedApplications` export into five consecutive byte-identical ones. Its first version truncated paged sub-responses to 5 of 52 items, since the JSON conversion had dropped `@odata.nextLink`, and following the link per caller fixed it.

## How to measure without lying to yourself

Half of this part is numbers, so let me tell you what it took to make them mean anything. I am listing these with some feeling, since every one of them cost us at least one confidently wrong conclusion first.

- **Battery power falsifies everything.** The same Intune export measured 190 to 258 seconds on battery and 80 to 137 on mains, and the module import 14 to 21 seconds against 4 to 8. Every benchmark session in this series was paused the moment the laptop left the desk, and yes, that includes the time I had to stop mid-run and pick it up again the next morning.
- **The profiler inflates the code it looks at.** `Trace-Script` made the Intune export take 638 seconds instead of 284, and scriptblock-heavy code inflates about 15 times more than the rest. A profile tells you *where*, but only an A/B run tells you *how much*.
- **Discard runs with retries.** The export harness records the Graph retry delay, and any run with a non-zero value gets thrown away, no exceptions. On my laptop an IPv6 route to Graph stalled just often enough to produce one plausible-looking outlier every few runs, including one glorious 51-minute run for 74 seconds of actual work.
- **Interleave A and B.** Machine state drifts within a session, and the same workload went from 17 to 25 to 35 seconds in one August afternoon with no code change whatsoever. Paired, alternating runs with the minimum or the median of three are the only comparisons we trust now.
- **Stage exactly one module version.** Two installed versions of a 10 MB module produce measurements of whichever one the engine resolved that time, so every September number comes from a directory junction to one version and nothing else on `PSModulePath`.
- **Count requests and HTTP time, not just wall clock.** An Azure AD export went 74, 59 and 73 seconds on three identical request sets. The request count and the HTTP time were rock steady, while the wall clock was backoff and load.
- **Diff the output.** Unit tests stayed green through a regression that dropped 80 percent of the service principals. A byte diff of the export caught it on the first run, and it has been the acceptance criterion for every export change since.

## Where part 2 leaves us

The runtime side is where we wanted it, with one open item we have chosen to leave open on purpose. Parsing an export is three to sixty times faster than before the conversion depending on its size, the comparison is an order of magnitude faster and allocates a twentieth of what it did, warm discovery is instant, and a full Intune export takes a quarter of the time it took in August, with Exchange Online at a third. The import still costs five seconds on PowerShell 7, with a floor of 3.8 that only a different layout can move, and we know precisely what each layout would cost. The generators are in the repository, and the decision waits on DSCv3.

Which leaves the one path this part has not touched at all. Compiling a configuration did not get three seconds worse, it got fifty seconds worse, and fixing it meant taking over the compiler itself. That is [part 3](./class-based-resources-part-3.md).
