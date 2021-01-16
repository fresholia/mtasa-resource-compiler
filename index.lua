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