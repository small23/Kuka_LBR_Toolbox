package serverUtils;

import static com.kuka.roboticsAPI.motionModel.BasicMotions.linRel;
import static com.kuka.roboticsAPI.motionModel.BasicMotions.splRel;

import java.util.ArrayList;

import sun.reflect.generics.reflectiveObjects.NotImplementedException;

import com.kuka.roboticsAPI.geometricModel.Frame;
import com.kuka.roboticsAPI.motionModel.RelativeSplineMotionCP;

public class ServerUtils
{

	public static RelativeSplineMotionCP<?> GetNewSplinePoint(
			ArrayList<Double> motionData, int dataCount, int moveType)
	{
		RelativeSplineMotionCP<?> tempRelMove = null;
		if (moveType == 48 - 128)
			tempRelMove = splRel();
		else if (moveType == 32 - 128)
			tempRelMove = linRel();
		else
			throw new NotImplementedException();
		tempRelMove.setXOffset(motionData.get(0));
		tempRelMove.setYOffset(motionData.get(1));
		tempRelMove.setZOffset(motionData.get(2));
		if (dataCount >= 6)
		{
			tempRelMove.setAOffset(motionData.get(3));
			tempRelMove.setBOffset(motionData.get(4));
			tempRelMove.setCOffset(motionData.get(5));
		}
		return tempRelMove;
	}

	public static Frame GetNewFrame(ArrayList<Double> motionData, int startIndex)
	{
		Frame tempAF = new Frame();
		tempAF.setX(motionData.get(startIndex+0));
		tempAF.setY(motionData.get(startIndex+1));
		tempAF.setZ(motionData.get(startIndex+2));
		tempAF.setX(motionData.get(startIndex+3));
		tempAF.setX(motionData.get(startIndex+4));
		tempAF.setX(motionData.get(startIndex+5));
		return tempAF;
	}
}
