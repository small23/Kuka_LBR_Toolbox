function [status, message, res] = DataGetDebugCoords(obj)
%DATAGETDEBUGCOORDS Summary of this function goes here
%   Detailed explanation goes here
IReceiveData(obj, 1, "int32");
res.coords = IReceiveData(obj, 6, "double");
res.e1=IReceiveData(obj,1,"double");
status = IReceiveData(obj,1,"int32");
res.turn = IReceiveData(obj,1,"int32");
res.angels=IReceiveData(obj, 7, "double");
message = "OK";
end

