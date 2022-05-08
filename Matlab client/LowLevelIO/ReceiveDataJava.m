function res = ReceiveDataJava(obj, count, type)
%RECEIVEDATAJAVA Safe data reader from java socket
%   Detailed explanation goes here
if (count == 0)
    res=[];
    return;
end
flag=1;
switch type
    case "uint8"
        res=uint8(zeros(1,count));
        datasize=int32(count);
        flag=0;
        buffer=zeros(1, datasize+1, 'int8');
    case "char"
        res=char(zeros(1,count));
        datasize=int32(count);
        flag=0;
        buffer=zeros(1, datasize+1, 'int8');
    case "double"
        res=double(zeros(1,count));
        datasize=int32(8*count);
        buffer=zeros(1, datasize, 'int8');
    case "int64"
        res=int64(zeros(1,count));
        datasize=int32(8*count);
        buffer=zeros(1, datasize, 'int8');
    case "uint64"
        res=uint64(zeros(1,count));
        datasize=int32(8*count);
        buffer=zeros(1, datasize, 'int8');
    case "int32"
        res=int32(zeros(1,count));
        datasize=int32(4*count);
        buffer=zeros(1, datasize, 'int8');
    case "uint32"
        res=uint32(zeros(1,count));
        datasize=int32(4*count);
        buffer=zeros(1, datasize, 'int8');
    case "single"
        res=single(zeros(1,count));
        datasize=int32(4*count);
        buffer=zeros(1, datasize, 'int8');
end
joa = java.util.Arrays.asList({buffer, int32(0), int32(datasize)}).toArray();
clk=tic();
try
    while toc(clk)<obj.lbr.timeout
        if obj.lbr.in.available>=datasize
            obj.lbr.wrapper.inner_method.invoke(obj.lbr.in, joa);
            if flag
                res=flip(typecast(flip(joa(1)'),type));
            else
                if (type=="char")
                    res=typecast(joa(1),"uint8");
                    res=char(res);
                else
                    res=typecast(joa(1),type);
                end
                res=res(1:datasize)';
            end
            break;
        end
    end
    if toc(clk)>=obj.lbr.timeout
        warning("Reading timeout! Cant receive enouth information (%i, %s) from Java Socket!", int32(count), type);
    end
catch ME
        warning("Error occured while reading data from Java Socket! " + ME.message);
end
end