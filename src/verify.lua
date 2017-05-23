-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local types = require("miss-validator.src.types")

-- @brief       verify input by params
-- @param       input   {object} 
-- @param       params  {array[object]} 
--              {
--                      {
--                              name            = {string}
--                              required        = {boolean}
--                              length          = {number}
--                              minLength       = {number}
--                              maxLength       = {number}
--                              type            = {string}
--                              pattern         = {string|object(boolean)}
--                              gt              = {number}
--                              lt              = {number}
--                              ge              = {numner}
--                              le              = {number}
--                              children        = {array(object)}
--                              default         = {string|boolean|number|numberic|object|array}
--                      }
--              }
-- @return      msg     {string}
--              msg == nil => ok
--              msg ~= nil => error msg
local function verify(input, params)
        return types.object(input, params, "")
end

return verify
