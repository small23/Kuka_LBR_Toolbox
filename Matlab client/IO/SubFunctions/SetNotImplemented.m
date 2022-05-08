function [status, message, res] = SetNotImplemented(~)
%SETNOTIMPLEMENTED Summary of this function goes here
%   Detailed explanation goes here
status=9;
message = "This function is not implemented yet!";
res = [];
warning(string(datetime)  + " "+ message);
end

