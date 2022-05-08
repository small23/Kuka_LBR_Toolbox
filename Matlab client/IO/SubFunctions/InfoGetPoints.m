function [status, message, res] = InfoGetPoints(obj)
%INFOGETPOINTS Summary of this function goes here
%   Detailed explanation goes here

dataSize=IReceiveData(obj, 1, "int32");
res=struct([]);
for i=1:dataSize
    namesize=IReceiveData(obj, 1, "int32");
    name = IReceiveData(obj, namesize, "char");
    devicesize=IReceiveData(obj, 1, "int32");
    device = IReceiveData(obj, devicesize, "char");
    coords = IReceiveData(obj, 6, "double");
    res(end+1).name = string(name);
    res(end).device = string(device);
    res(end).coord=coords(1:3);
    res(end).orient=coords(4:6);
    res(end).e1=[];
    res(end).turn=[];
    res(end).status=[];
    flagE1 = IReceiveData(obj, 1, "uint8");
    if (flagE1>0)
        res(end).e1 = IReceiveData(obj, 1, "double");
    end
    flagStatus = IReceiveData(obj, 1, "uint8");
    if (flagStatus>0)
        res(end).status = IReceiveData(obj, 1, "int32");
    end
    flagTurn = IReceiveData(obj, 1, "uint8");
    if (flagTurn>0)
        res(end).turn = IReceiveData(obj, 1, "int32");
    end  
end
status=0;
message = "OK";
end

