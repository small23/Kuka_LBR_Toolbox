function [status, message, res] = SetMotionError(~)
%SETMOTIONERROR Summary of this function goes here
%   Detailed explanation goes here
status=6;
message = "Robot can`t execute specified motion!";
res = [];
warning(string(datetime)  + " "+ message);
end

