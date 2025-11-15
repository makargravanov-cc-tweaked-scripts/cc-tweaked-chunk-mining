local logFile = fs.open("log_" .. getFileTimestamp(), "a")

--- @param text string
--- @return string
function log(text)
    print(text)
    logFile.write("[" .. getTimestamp() .. "]: " .. text)
end

--- @return string
function GetFileTimestamp()
    return os.date("%Y_%m_%d_%H_%M_%S.txt", os.epoch("local") / 1000)
end

--- @return string
function GetTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S", os.epoch("local") / 1000)
end