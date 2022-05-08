function [status, message, res] = SetArgumentError(~)
%SETARGUMENTERROR Summary of this function goes here
%   Detailed explanation goes here
status=1;
message = "Invalid argument (range or type) while parsing data!";
warning(string(datetime)  + " "+ message);
res = [];
end

