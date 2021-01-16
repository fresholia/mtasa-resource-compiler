# MTA:SA File(s) Compiler

You can encrypt all files on your resource with this module. You can read the documents below and use the module.


### Introduction

The system does not work with export for security reasons. You need to add certain files to your system.
So add the following files to your system.
```js
compiler.lua
classes.lua
```
<hr>

Don't forget to add the following code above where you will run the module:
```lua
local compiler = load(compiler)
```

### Function definitions

*compiler:* set

**USE:**
```lua
compiler:set({
    compileExtensions = "png,txd", --valid extensions: png, txd, jpg, jpeg, gif, dff, txd, ipb
    key = "", -- your crypt key, If you want it to be different for each resource you can use ( md5(getResourceName(getThisResource)) ) 
    duplicate = true, -- Leave true if you want it to encrypt pictures every resource starts.
    saveMetaXML = true, -- Enter whether it saves to meta.xml when encrypted or decrypted (true/false)
    restartOnDone = false --Restarting the system when done, absolutely necessary (require acl)
})
```

<hr>

*compiler:* compile

**USE:**

***Sync use:***
```lua
compiler:compile()
```

***Async use:***
```lua
compiler:compile()
    .on("complete",
        function(self, total)

        end
    )
    .on("error",
        function(err)
            
        end
    )
```

<hr>

*compiler:* decrypt

**USE:**

***Sync use:***
```lua
compiler:decrypt()
```

***Async use:***
```lua
compiler:decrypt()
    .on("complete",
        function(self, total)

        end
    )
    .on("error",
        function(err)
            
        end
    )
```

<hr>

## Full Example:

```lua
local compiler = load(compiler)

compiler:set({
    compileExtensions = "png,txd",
    key = "aa-q3",
    duplicate = true,
    saveMetaXML = true,
    restartOnDone = false
})

addCommandHandler("compile",
    function()
        compiler:compile()
            .on("complete",
                function(self, total)
                    
                end
            )
            .on("error",
                function(err)
                    print("ERR: "..err)
                end
            )
    end
)
addCommandHandler("decrypt",
    function()
        compiler:decrypt()
            .on("complete",
                function(self, total)
                    
                end
            )
            .on("error",
                function(err)
                    print("ERR: "..err)
                end
            )
    end
)
```

<hr>

### Add this to the top of the client file you encrypted

```lua
local compiler = load(compiler)
loadstring(compiler:loadFunctions())()
```
