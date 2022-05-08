function [status, message, res] = DataGetForce(obj)
%DATAGETFORCE Summary of this function goes here
%   Detailed explanation goes here
dataSize=IReceiveData(obj, 1, "int32");
res = IReceiveData(obj, dataSize, "double");
status=0;
message = "OK";
end

