function [status, message, res] = SetErrStatus(~)
%SETERRSTATUS Summary of this function goes here
%   Detailed explanation goes here
status=3;
res = [];
message = " Undefined error!";
warning(string(datetime)  + message);
end