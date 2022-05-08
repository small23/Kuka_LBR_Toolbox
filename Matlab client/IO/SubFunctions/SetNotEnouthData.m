function [status, message, res] = SetNotEnouthData(~)
%SETNOTENOUTHDATA Summary of this function goes here
%   Detailed explanation goes here
status=7;
message = "Not enouth data in sended command!";
res = [];
warning(string(datetime)  + " "+ message);
end

