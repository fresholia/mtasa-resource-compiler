compiler = new "compiler";

local fileExists = fileExists
local fileOpen = fileOpen
local fileRead = fileRead
local fileGetSize = fileGetSize
local print = print
local xmlLoadFile = xmlLoadFile
local xmlNodeGetChildren = xmlNodeGetChildren
local xmlNodeGetAttribute = xmlNodeGetAttribute

function compiler.prototype.____constructor(self)
    self.list = {}
    self.decryptedList = {}
    self.data = {
       backupFolder = "backup",
       key = "this-is-protect" 
    }
    self.compileExtensions = {}

    self.decryptSelf = {}
    self.cryptSelf = {}
end

if triggerClientEvent then

function compiler.prototype.readMetaData(self)
    local list = self.compileExtensions

    local meta = xmlLoadFile("meta.xml")
    local metaData = xmlNodeGetChildren(meta)
    local fileCache, decryptedCache = {}, {}
    if metaData then
        for index, node in ipairs(metaData) do
            local fileType = xmlNodeGetName(node)
            local fileLocation = xmlNodeGetAttribute(node, "src")
            local fileData = fileLocation:split(".")
            if fileType == "file" and self.compileExtensions[fileData[#fileData]] then
                fileCache[#fileCache + 1] = {name=fileData[#fileData-1], extension=fileData[#fileData], fullPath = fileLocation}
            elseif fileType == "file" and fileData[#fileData]:sub(-2) == "~c" then
                decryptedCache[#decryptedCache + 1] = {name=fileData[#fileData-1], extension=fileData[#fileData], fullPath = fileLocation}
            end
        end
    end
    xmlUnloadFile(meta)

    if fileExists("meta.xml~") then
        fileDelete("meta.xml~")
    end

    local metaFile = fileCreate("meta.xml~")
    if metaFile then
        local originalMetaFileData
        local oMetaFile = fileOpen("meta.xml")
        if oMetaFile then
            originalMetaFileData = fileRead(oMetaFile, fileGetSize(oMetaFile))
        end

        fileWrite(metaFile, originalMetaFileData)
        fileClose(metaFile)
        fileClose(oMetaFile)
    end

    self.list = fileCache
    self.decryptedList = decryptedCache
    return true
end

function compiler.prototype.saveMetaData(self, type)
    local list = type == "compile" and self.list or self.decryptedList

    local meta = xmlLoadFile("meta.xml~")
    local metaData = xmlNodeGetChildren(meta)
    local fileCache, decryptedCache = {}, {}
    if metaData then
        for index, node in ipairs(metaData) do
            local fileType = xmlNodeGetName(node)
            local fileLocation = xmlNodeGetAttribute(node, "src")
            local fileData = fileLocation:split(".")
            
            if type == "compile" and self.compileExtensions[fileData[#fileData]] then
                xmlNodeSetAttribute(node, "src", fileLocation:gsub("~c", "").."~c")
            elseif fileData[#fileData]:sub(-2) == "~c" then
                xmlNodeSetAttribute(node, "src", fileLocation:gsub("~c", ""))
            end
        end
    end
    xmlSaveFile(meta)
    xmlUnloadFile(meta)

    fileDelete("meta.xml")
    fileRename("meta.xml~", "meta.xml")
    return true
end

function compiler.prototype.set(self, list)
    assert(list, "Please use compiler:set({...})")

    self.data = list

    setElementData(resourceRoot, "cryptKey", self.data.key)

    local list = split(self.data.compileExtensions, ",")

    for index, extension in ipairs(list) do
        self.compileExtensions[extension] = true
    end

    self:readMetaData()

    return true
end

function compiler.prototype.done(self, type)
    if type == "compile" then
        print("[Compiler]: Resources compiled succesfuly")

        if self.doneCallback then
            self:doneCallback(#self.list)
        end
    else
        print("[Compiler]: Resources decrypt succesfuly.")

        if self.doneDecryptCallback then
            self:doneDecryptCallback(#self.list)
        end
    end

    if self.data.saveMetaXML then
        self:saveMetaData(type)
        print("[Compiler]: Saving meta.xml data")
    end
    if self.data.restartOnDone then
        restartResource(getThisResource())
    end
end

function compiler.prototype.next(self, type, currentID)
    if type == "compile" then
        if self.list[currentID + 1] then
            self:compileFiles(currentID + 1)
        else
            self:done(type)
        end
    else
        if self.decryptedList[currentID + 1] then
            self:decryptFiles(currentID + 1)
        else
            self:done(type)
        end
    end
end

function compiler.prototype.compileFiles(self, currentID)
    local data = self.list[currentID]
    local file = fileExists(data.fullPath.."~c")

    local compiledStr
    local compiledFile = fileOpen(data.fullPath)
    if compiledFile then
        compiledStr = fileRead(compiledFile, fileGetSize(compiledFile))
        fileClose(compiledFile)
    end

    if not self.data.duplicate and file then

        print("[Compiler]: Compiled file ("..data.fullPath.."~c"..") already exists. Please use compiler:set({duplicate = true, ...})")

        if self.errorCallback then
            self.errorCallback("Compiled file ("..data.fullPath.."~c"..") already exists. Please use compiler:set({duplicate = true, ...})")
            return
        end

        return
    elseif file and self.data.duplicate then
        fileDelete(data.fullPath.."~c")
    end

    local file = fileCreate(data.fullPath.."~c")
    if file then
        encodeString("tea", compiledStr, {key=self.data.key},
            function(str)
                fileWrite(file, str)
                fileClose(file)
                print("[Compiler]: Encoding succesfuly '"..data.name.."."..data.extension.."' file, next->")

                self:next('compile', currentID)
            end
        )
    end

    return true
end

function compiler.prototype.compile(self)
    print("[Compiler]: Started encoding ".. #self.list .." files.")

    self:compileFiles(1)

    self.cryptSelf.on = function(state, callback)
        switch {
            state,
            case = {
                ["complete"] = function()
                    self.doneCallback = callback or false
                end;
                ["error"] = function()
                    self.errorCallback = callback or false
                end;
            }
        }
        return self.cryptSelf
    end

    return self.cryptSelf
end

function compiler.prototype.decryptFiles(self, currentID)
    local data = self.decryptedList[currentID]
    if not data then
        print("[Compiler]: Couldn't find encrypted files, please use compiler:compile() first.")
        if self.errDecryptCallback then
            self.errDecryptCallback("Couldn't find encrypted files, please use compiler:compile first.")
        end
        return
    end
    local file = fileExists(data.fullPath:gsub("~c", ""))

    local compiledStr
    local compiledFile = fileOpen(data.fullPath)
    if compiledFile then
        compiledStr = fileRead(compiledFile, fileGetSize(compiledFile))
        fileClose(compiledFile)
    end

    if not self.data.duplicate and self.compileExtensions[(data.extension):gsub("~c", "")] then
        print("[Compiler]: Decrypted file already exists. Please use compiler:set({duplicate = true, ...})")
        if self.errDecryptCallback then
            self.errDecryptCallback("Decrypted file already exists. Please use compiler:set({duplicate = true, ...})")
        end
        self:next('decrypt', currentID)
        return
    elseif file and self.data.duplicate then
        fileDelete(data.fullPath:gsub("~c", ""))
    end
    

    local file = fileCreate(data.fullPath:gsub("~c", ""))
    if file then
        decodeString("tea", compiledStr, {key=self.data.key},
            function(str)
                fileWrite(file, str)
                fileClose(file)
                fileDelete(data.fullPath)
                print("[Compiler]: Decoding succesfuly '"..data.name.."."..data.extension.."' file, next->")

                self:next('decrypt', currentID)
            end
        )
    else
        if self.errDecryptCallback then
            self.errDecryptCallback("Couldn't create file.")
        end
    end

    return true
end

function compiler.prototype.decrypt(self)
    print("[Compiler]: Started decoding ".. #self.list .." files.")
    
    self:decryptFiles(1)

    self.decryptSelf.on = function(state, callback)
        switch {
            state,
            case = {
                ["complete"] = function()
                    self.doneDecryptCallback = callback or false
                end;
                ["err"] = function()
                    self.errDecryptCallback = callback or false
                end;
            }
        }
        return self.decryptSelf
    end

    return self.decryptSelf
end

else

function compiler.prototype.loadFunctions(self)
    local cryptKey = getElementData(resourceRoot, "cryptKey")

    local encodedFunctions = [[
        local dxDrawImage = dxDrawImage
        local engineLoadIFP = engineLoadIFP
        local engineLoadDFF = engineLoadDFF
        local engineLoadTXD = engineLoadTXD

        local textures = {}
        function dxDrawImage(x,y,w,h,img, r, rx, ry, color, postgui)
            if type(img) == "string" then
                if not textures[img] then
                    local splitString =  img:split(".")
                    local decryptedImg
                    if (splitString[#splitString]).sub(-2) == "~c" then
                        local file = fileOpen(img)
                        decryptedImg = fileRead(file, fileGetSize(file))
                        decryptedImg = decodeString("tea", decryptedImg, {key = cryptKey})
                        fileClose(file)
                    else
                        decryptedImg = img
                    end
                    textures[img] = dxCreateTexture(decryptedImg, "argb", true, "clamp")
                end
                img = textures[img]
            end
            return _dxDrawImage(x,y,w,h,img, r, rx, ry, color, postgui)
        end
    ]]

    return encodedFunctions
end

end

return compiler
