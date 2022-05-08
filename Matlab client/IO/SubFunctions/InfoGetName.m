function [status, message, res] = InfoGetName(obj)
%INFOGETNAME Summary of this function goes here
%   Detailed explanation goes here
nameLen = IReceiveData(obj, 1, "int32");
res = string(IReceiveData(obj, nameLen, "char"));
status=0;
message = "OK";
end

