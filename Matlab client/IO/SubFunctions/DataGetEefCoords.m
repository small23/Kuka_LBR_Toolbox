function [status, message, res] = DataGetEefCoords(obj)
%DATAGETEEFCOORDS Summary of this function goes here
%   Detailed explanation goes here
IReceiveData(obj, 1, "int32");
res.coords = IReceiveData(obj, 6, "double");
res.e1=IReceiveData(obj,1,"double");
res.statusF = IReceiveData(obj,1,"int32");
res.turn = IReceiveData(obj,1,"int32");
message = "OK";
status = 0;
end

