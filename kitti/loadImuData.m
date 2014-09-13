function [imuData, frameRange] = loadImuData(imuDataFolder, imageTimestamps)
% loadImageData Read captured image data into memory. Tries to load
% individual images or a saved mat file if one exists.
    

    %Read IMU data
    oxtsData = loadOxtsliteData(imuDataFolder);
    % load IMU Data
    v_index = [9:11]; % FLU frame
    a_index = 12:14; % 12:14 body frame, 15:17 FLU frame
    omega_index = 18:20; % 18:20 body frame, 21:23 FLU frame

       
    dateStrings = loadTimestamps([imuDataFolder '/oxts']);
    timestamps = zeros(1, length(dateStrings));
    for i = 1:length(dateStrings)
        timestamps(i) =  datenum_to_unixtime(datenum(dateStrings(i))) + 0.01;
    end
    
    frameRange = find(timestamps > imageTimestamps(1) & timestamps < imageTimestamps(end) + 1);
    frameNum = length(frameRange);
    imuData.timestamps = zeros(1, frameNum);
    imuData.measAccel = zeros(3, frameNum);
    imuData.measOrient = zeros(4, frameNum);
    imuData.measOmega = zeros(3,frameNum);
    imuData.initialVelocity = zeros(3,1);
    
   
    % for all oxts packets do
    for meas_i=1:length(frameRange)

      i = frameRange(meas_i);
      % if there is no data 
      if isempty(oxtsData{i})
        continue;
      end
      
      if meas_i == 1
          imuData.initialVelocity = getRnb(oxtsData{i})'*[ oxtsData{i}(8); oxtsData{i}(7); 0; ];
      end
      
     imuData.timestamps(1,meas_i) = timestamps(i);
     imuData.measAccel(:,meas_i) =  oxtsData{i}(a_index)';
     imuData.measOmega(:,meas_i) = oxtsData{i}(omega_index);

      
      rx = oxtsData{i}(4); % roll
      ry = oxtsData{i}(5); % pitch
      rz = oxtsData{i}(6); % heading 
      Rx = [1 0 0; 0 cos(rx) -sin(rx); 0 sin(rx) cos(rx)]; % base => nav  (level oxts => rotated oxts)
      Ry = [cos(ry) 0 sin(ry); 0 1 0; -sin(ry) 0 cos(ry)]; % base => nav  (level oxts => rotated oxts)
      Rz = [cos(rz) -sin(rz) 0; sin(rz) cos(rz) 0; 0 0 1]; % base => nav  (level oxts => rotated oxts)
      R  = Rz*Ry*Rx;

      imuData.measOrient(:,meas_i) = quat_from_rotmat(R);
     
    end
    
    function dn = datenum_to_unixtime( date_num )
      dn =  (date_num - 719529)*86400;         %# 719529 == datenum(1970,1,1)
    end
    
end