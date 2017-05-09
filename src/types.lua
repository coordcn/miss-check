-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local _M = {}

local LENGTH_EQ = " length must be equal to "
local LENGTH_GE = " length must be great then or equal to "
local LENGTH_LE = " length must be less then or equal to "
local NUMBER_GT = " must be great then "
local NUMBER_GE = " must be great then or equal to "
local NUMBER_LT = " must be less then "
local NUMBER_LE = " must be less then or equal to "

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

local function handleNil(param, names)
        if param.required then
                return nil, names .. " is required"
        else
                return param.default, nil
        end
end

function _M.string(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "string" then
                return nil, names .. " must be string" 
        end

        local length = #value
        local msg = checkLength(param, length, names)
        if msg then
                return nil, msg
        end

        local pattern = param.pattern
        local patternType = type(pattern)
        if patternType == "string" then
                local match = string.match(value, pattern)
                if match ~= value then
                        return nil, names .. " has invalid charactors" 
                end
        elseif patternType == "table" then
                if not pattern[value] then
                        if param._pattern then
                                return nil, names .. " must be one of " .. param._pattern  
                        else
                                local ret, err = cjson.encode(pattern)
                                if ret then
                                        param._pattern = ret
                                        return nil, names .. " must be one of " .. ret
                                else
                                        error(names .. " pattern json encode error " .. err)
                                end
                        end
                end
        end
        
        return value, nil
end

function _M.boolean(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "boolean" then
                return nil, names .. " must be boolean" 
        end

        return value,  nil
end

function _M.number(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "number" then
                return nil, names .. " must be number" 
        end

        local msg = checkNumber(value, param, names)
        if msg then
                return nil, msg
        end

        return value, nil
end

function _M.numberic(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        local valueType = type(value)
        if valueType == "number" then
        elseif valueType == "string" then
                value = tonumber(value)
                if not value then
                        return nil, names .. " is invalid number" 
                end
        else
                return nil, names .. " must be number or string" 
        end

        local msg = checkNumber(value, param, names)
        if msg then
                return nil, msg
        end

        return value, nil
end

function _M.object(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "table" then
                return nil, names .. " must be object" 
        end

        for i = 1, #param do
                local arg       = param[i]
                local handle    = _M[arg.type]
                local argName   = arg.name
                local tmp       = value[argName]
                local tmpNames  = names .. "." .. argName
                local val, msg  = handle(tmp, arg, tmpNames)
                if msg then
                        return nil, msg
                end

                value[argName] = val
        end

        return value, nil
end

function _M.array(value, param, names)
        if value == nil then
                return handleNil(param, names)
        end

        if type(value) ~= "table" then
                return nil, names .. " must be array" 
        end

        local length = #value
        local msg = checkLength(param, length, names)
        if msg then
                return nil, msg
        end

        local arg = param.children[1]
        local argType = arg.type
        local handle = _M[argType]
        for i = 1, length do
                local tmp       = value[i]
                local tmpNames  = names .. "[" .. i .. "]"
                local val, msg  = handle(tmp, arg, tmpNames)
                if msg then
                        return nil, msg
                end

                value[i] = val
        end

        return value, nil
end

return _M
