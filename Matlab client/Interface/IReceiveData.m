function res = IReceiveData(obj, count, type)
%IRECEIVEDATA Summary of this function goes here
%   Detailed explanation goes here
arguments
    obj
    count double
    type string {mustBeMember(type,["uint8","char", "double", "int64", "uint64", "int32", "uint32", "single"])}
end

if obj.mode=="fast"
    res = ReceiveDataTCPIP(obj, count, type);
elseif obj.mode=="safe"
    res = ReceiveDataTCPClient(obj, count, type);
elseif obj.mode=="java"
    res = ReceiveDataJava(obj, count, type);
end
end