function [status, message, res] = InfoGetIo(obj)
%INFOGETIO Summary of this function goes here
%   Detailed explanation goes here
IReceiveData(obj, 1, "int32");
groupNumbers = IReceiveData(obj, 1, "int32");
res=struct([]);
for i=1:groupNumbers
    nameLen = IReceiveData(obj, 1, "int32");
    ioGroupName = IReceiveData(obj,nameLen, "char");
    ioPorts = IReceiveData(obj, 1, "int32");
    for j=1:ioPorts
        ioPortLen = IReceiveData(obj, 1, "int32");
        ioPortName = IReceiveData(obj, ioPortLen, "char");
        ioType = IReceiveData(obj,1,"uint8");
        res(end+1).group = string(ioGroupName);
        res(end).name = string(ioPortName);
        switch ioType
            case 0
                res(end).type="ANALOG";
            case 1
                res(end).type="BOOLEAN";
            case 2
                res(end).type="INTEGER";
            case 3
                res(end).type="UNSIGNED_INTEGER";
        end
        res(end).typeIO = "Input";
    end
    ioPorts = IReceiveData(obj, 1, "int32");
    for j=1:ioPorts
        ioPortLen = IReceiveData(obj, 1, "int32");
        ioPortName = IReceiveData(obj, ioPortLen, "char");
        ioType = IReceiveData(obj,1,"uint8");
        res(end+1).group = string(ioGroupName);
        res(end).name = string(ioPortName);
        switch ioType
            case 0
                res(end).type="ANALOG";
            case 1
                res(end).type="BOOLEAN";
            case 2
                res(end).type="INTEGER";
            case 3
                res(end).type="UNSIGNED_INTEGER";
        end
        res(end).typeIO = "Output";
    end
end
T = struct2table(res);
T = sortrows(T, 'name');
res = table2struct(T);
status=0;
message = "OK";
end

