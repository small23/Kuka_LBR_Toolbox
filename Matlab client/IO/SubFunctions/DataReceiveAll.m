function [status, message, res] = DataReceiveAll(obj)
%DATARECEIVEALL Summary of this function goes here
%   Detailed explanation goes here
dataSize=IReceiveData(obj, 1, "int32");
data = IReceiveData(obj, dataSize, "double");
res.angles=data(4:10);
res.force=data(1:3);
res.joints=reshape(data(11:end),3,[])';
status=0;
message = "OK";
end