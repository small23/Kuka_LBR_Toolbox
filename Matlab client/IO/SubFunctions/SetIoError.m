function [status, message, res] = SetIoError(~)
%SETIOERROR Summary of this function goes here
%   Detailed explanation goes here
status=5;
message = "Common IO Exception!";
res = [];
warning(string(datetime)  + " "+ message);
end

