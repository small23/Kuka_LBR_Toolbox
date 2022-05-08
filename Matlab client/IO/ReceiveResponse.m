function [data, status, msg] = ReceiveResponse(obj, command, waitReceive)
%PARCEDATA Summary of this function goes here
%   Detailed explanation goes here
arguments
    obj iiwa
    command = []
    waitReceive logical = false
end

if obj.mode == "offline"
    ME = MException('iiwa:InvalidState', ...
        "Library currently in offline mode! No communication allowed!");
    throw(ME)
end

if ~isempty(command)
    obj.flush();
    ISendData(obj, command);
end

if waitReceive
    while(~IBytesAvailable(obj))
        pause(5/1000);
    end
end

repl=IReceiveData(obj, 4, "uint8");
for i=1:size(obj.lbrAns,1)
    if isequal(obj.lbrAns{i,1}, repl)
        [status, msg, data] = obj.lbrAns{i,2}(obj);
        return;
    end
end

data=[];
status=102;
msg= string(datetime) + " Reply '" + string(char(repl)) + "' is not recognised!";
warning(msg);
end