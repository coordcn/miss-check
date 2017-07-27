-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local core      = require("miss-core")
local utils     = core.utils

local _M = {}

local LENGTH_EQ = " length must be equal to "
local LENGTH_GE = " length must be great then or equal to "
local LENGTH_LE = " length must be less then or equal to "
local NUMBER_GT = " must be great then "
local NUMBER_GE = " must be great then or equal to "
local NUMBER_LT = " must be less then "
local NUMBER_LE = " must be less then or equal to "
local ONE_OF    = " must be one of "

local function checkLength(param, length, names)
        if param.length then
                if length ~= param.length then
                        return names .. LENGTH_EQ .. param.length  
                end
        end

        if param.minLength then
                if length < param.minLength then
                        return names .. LENGTH_GE .. param.minLength  
                end
        end

        if param.maxLength then
                if length > param.maxLength then
                        return names .. LENGTH_LE .. param.maxLength  
                end
        end
end

local function checkNumber(value, param, names)
        if param.gt then
                if value <= param.gt then
                        return names .. NUMBER_GT .. param.gt  
                end
        end

        if param.ge then
                if value < param.ge then
                        return names .. NUMBER_GE .. param.ge  
                end
        end

        if param.le then
                if value > param.le then
                        return names .. NUMBER_LE .. param.le
                end
        end

        if param.lt then
                if value >= param.lt then
                        return names .. NUMBER_LT .. param.lt  
                end
        end
end

local function checkPattern(value, pattern, patternType, param, names)
        if patternType == "table" then
                if not pattern[value] then
                        if param._pattern then
                                return nil, names .. ONE_OF .. param._pattern  
                        else
                                local keys = utils.keys(pattern)
                                local ret, err = cjson.encode(keys)
                                if ret then
                                        param._pattern = ret
                                        return names .. ONE_OF .. ret
                                else
                                        error(names .. " pattern json encode error " .. err)
                                end
                        end
                end
        elseif patternType = "function" then
                if not pattern(value) then
                        return names .. " is invalid"
                end
        end
end

local function handleNil(param, names)
        if param.required then
                return names .. " is required"
        else
                return nil, param.default
        end
end

function _M.string(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "string" then
                return names .. " must be string" 
        end

        local length = #value
        local msg = checkLength(param, length, names)
        if msg then
                return msg
        end

        local pattern = param.pattern
        if pattern then
                local patternType = type(pattern)
                if patternType == "string" then
                        local match = string.match(value, pattern)
                        if match ~= value then
                                return names .. " has invalid charactors" 
                        end
                end

                msg = checkPattern(value, pattern, patternType, param, names)
                if msg then
                        return msg
                end
        end
        
        return nil, value
end

function _M.boolean(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "boolean" then
                return names .. " must be boolean" 
        end

        return nil, value
end

function _M.number(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "number" then
                return names .. " must be number" 
        end

        local pattern = param.pattern
        if pattern then
                local patternType = type(pattern)
                msg = checkPattern(value, pattern, patternType, param, names)
                if msg then
                        return msg
                end
        end

        local msg = checkNumber(value, param, names)
        if msg then
                return msg
        end

        return nil, value
end

function _M.numeric(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        local valueType = type(value)
        if valueType == "number" then
        elseif valueType == "string" then
                value = tonumber(value)
                if not value then
                        return names .. " is invalid number" 
                end
        else
                return names .. " must be number or string" 
        end

        local pattern = param.pattern
        if pattern then
                local patternType = type(pattern)
                msg = checkPattern(value, pattern, patternType, param, names)
                if msg then
                        return msg
                end
        end

        local msg = checkNumber(value, param, names)
        if msg then
                return msg
        end

        return nil, value
end

function _M.object(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "table" then
                return names .. " must be object" 
        end

        local args = param.children
        for i = 1, #args do
                local arg       = args[i]
                local handle    = _M[arg.type]
                local argName   = arg.name
                local tmp       = value[argName]
                local tmpNames  = names .. "." .. argName
                local val, msg  = handle(tmp, arg, tmpNames)
                if msg then
                        return msg
                end

                value[argName] = val
        end

        return nil, value
end

function _M.array(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "table" then
                return names .. " must be array" 
        end

        local length = #value
        local msg = checkLength(param, length, names)
        if msg then
                return msg
        end

        local arg = param.children[1]
        local argType = arg.type
        local handle = _M[argType]
        for i = 1, length do
                local tmp       = value[i]
                local tmpNames  = names .. "[" .. i .. "]"
                local val, msg  = handle(tmp, arg, tmpNames)
                if msg then
                        return msg
                end

                value[i] = val
        end

        return nil, value
end

return _M
