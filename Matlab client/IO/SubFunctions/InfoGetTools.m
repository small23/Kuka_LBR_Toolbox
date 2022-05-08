function [status, message, res] = InfoGetTools(obj)
%INFOGETTOOLS Summary of this function goes here
%   Detailed explanation goes here
nameLen = IReceiveData(obj, 1, "int32");
names = string(IReceiveData(obj, nameLen, "char"));
res = split(names,' ');
status=0;
message = "OK";
end

