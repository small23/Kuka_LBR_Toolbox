function res = SetPossibleAns()
%SETPOSSIBLEANS Summary of this function goes here
%   Detailed explanation goes here
% Format: {uint8('reply_from_iiwa, 4 letters'), @processing_function};

res = [
    {uint8('<CCR'), @ControlConnRx};
    {uint8('<DJV'), @DataGetJointVect};
    {uint8('<DJC'), @DataGetJointCs};
    {uint8('<DFF'), @DataGetForce};
    {uint8('<DTA'), @DataGetJointAng};
    {uint8('<DT='), @DataReceiveAll}; %Depricated
    {uint8('<IIO'), @InfoGetIo};
    {uint8('<INN'), @InfoGetName};
    {uint8('<IPD'), @InfoGetPoints};
    {uint8('<OKK'), @SetOkStatus};
    {uint8('<ITN'), @InfoGetTools};
    {uint8('<CTC'), @InfoGetName};
    {uint8('<DPD'), @DataGetDebugCoords};
    {uint8('<DKI'), @DataGetJointAng};
    {uint8('<DKF'), @DataGetJointCs};
    {uint8('<ITA'), @InfoGetEefTransformationAngle};
    {uint8('<ITV'), @InfoGetEefTransformationVector};
    {uint8('<DPE'), @DataGetEefCoords};
    {uint8('<CTF'), @InfoGetToolFrames};
    %Error handlers
    {uint8('<ERR'), @SetErrStatus}; %Depricated
    {uint8('<EIO'), @SetIoError};
    {uint8('<EIC'), @SetInvalidCommand};
    {uint8('<EED'), @SetNotEnouthData};
    {uint8('<ESE'), @SetMotionError};
    {uint8('<EAE'), @SetArgumentError};
    {uint8('<ENI'), @SetNotImplemented};
    {uint8('<ENF'), @SetNotFound};
    {uint8('<ECE'), @SetCannotExecute};
    {uint8('<ENP'), @SetNullPointer};
    ];
end