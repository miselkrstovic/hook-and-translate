## THIS PROJECT IS CURRENTLY UNMAINTAINED
---
# Hook and Translate

## About

Hook and Translate, is an application that provides a runtime method of training/translating Windows applications, using Win32 DLL hooking.

## Compatibility

The project was only tested on Windows XP, and thus is not guaranteed to work on later versions of Windows.

*NOTICE: Project needs to be upgraded to work with the latest version of RAD Studio.*

## TODO
* Migrate to latest version of RAD Studio
* Update win32 calls and added platform specific checks
* Add command line "/t" to start application in training mode with GUI
* Use binary trees or similar to speedup lookups
* Add regex matching to strings detection/lookup/replace
* Problems with labels and wrong fonts
	* Intercept `TextOut`, `TextOutEx`, `DrawText`, `DrawTextEx`, `ExtTextOut`, `PolyTextOut`, `TabbedTextOut`
* Find why menu translation is being lost and not persisted
* Recheck hook freeing at application shutdown

## License

Hook and Translate is licensed under the MIT License. See [LICENSE](LICENSE.md) for details.
