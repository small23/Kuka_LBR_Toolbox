function [status, message, res] = SetInvalidCommand(~)
%SETINVALIDCOMMAND Summary of this function goes here
%   Detailed explanation goes here
status=4;
message = "Invalid command!";
res = [];
warning(string(datetime)  + " "+ message);
end

