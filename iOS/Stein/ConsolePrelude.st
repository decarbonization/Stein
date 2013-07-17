`
    file    ConsolePrelude.st
    purpose To prepare the console environment for use by real people.
    notes   $__Console_CWD and $__Console_CWD_Default are defined as variables before the ConsolePrelude is executed.
`

`
    function    $__resolve
    purpose     To resolve a partial path or absolute string to a URL.
`
func $__resolve(part) {
    if part {
        let maybe-url = NSURL URLWithString:part
        decide maybe-url {
            maybe-url
        } {
            $__Console_CWD URLByAppendingPathComponent:new-cwd
        }
    } {
        $__Console_CWD
    }
}

`
    function    cwd
    purpose     To return the current working directory.
`
func cwd() {
    $__Console_CWD
}

`
    function    cd
    purpose     To change the current working directory.
    forms {
        ()
        (location-or-part)
    }
`
func cd(new-cwd) {
    decide new-cwd {
        let maybe-url = NSURL URLWithString:new-cwd
        decide maybe-url {
            set! $__Console_CWD maybe-url
        } {
            set! $__Console_CWD ($__Console_CWD URLByAppendingPathComponent:new-cwd)
        }
    } {
        set! $__Console_CWD $__Console_CWD_Default
    }
}

`
    function    ls
    purpose     To print the current working directory, or a specified path.
    forms {
        ()
        (location-or-part)
    }
`
func ls(inLocation) {
    declare location
    match (inLocation class) {
        NSString    { set! location ($__resolve inLocation) }
        NSURL       { set! location inLocation }
        _           { set! location (cwd ()) }
    }
    
    (NSFileManager defaultManager) contentsOfDirectoryAtURL:location includingPropertiesForKeys:nil options:0 error:nil
}

"stein ready." print
