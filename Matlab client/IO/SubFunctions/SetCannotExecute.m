function [status, message, res] = SetCannotExecute(~)
%SETCANNOTEXECUTE Summary of this function goes here
%   Detailed explanation goes here
status=2;
message = "Can`t execute current command!";
warning(string(datetime)  + " "+ message);
res = [];
end

