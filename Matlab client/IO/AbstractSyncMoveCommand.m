function [status, msg] = AbstractSyncMoveCommand(obj, motions, type)
%MOVECOMMAND Summary of this function goes here
%   Detailed explanation goes here
if size(motions,1)<0
    status = 200;
    msg = "No data provided!";
    return
end
sendStr=PackMovementCommand(motions, type);
[~, status, msg] = ReceiveResponse(obj, sendStr, true);
end