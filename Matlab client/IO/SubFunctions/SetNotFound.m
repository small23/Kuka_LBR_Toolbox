function [status, message, res] = SetNotFound(~)
%SETNOTFOUND Summary of this function goes here
%   Detailed explanation goes here
status=8;
message = "Requested object not found! Check name.";
res = [];
warning(string(datetime)  + " "+ message);
end

