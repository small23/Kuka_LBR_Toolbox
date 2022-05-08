function [status, message, res] = SetNullPointer(~)
%SETNULLPOINTER Summary of this function goes here
%   Detailed explanation goes here
status=10;
message = "Server catch NullPointer exception!";
res = [];
warning(string(datetime)  + " "+ message);
end

