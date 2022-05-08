package serverUtils;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

import com.kuka.common.params.IParameterSet;
import com.kuka.roboticsAPI.deviceModel.JointPosition;
import com.kuka.roboticsAPI.deviceModel.LBR;
import com.kuka.roboticsAPI.deviceModel.LBRE1Redundancy;
import com.kuka.roboticsAPI.geometricModel.Frame;
import com.kuka.roboticsAPI.geometricModel.ObjectFrame;
import com.kuka.roboticsAPI.geometricModel.Tool;
import com.kuka.roboticsAPI.geometricModel.World;
import com.kuka.roboticsAPI.geometricModel.math.Matrix;
import com.kuka.roboticsAPI.geometricModel.math.MatrixBuilder;
import com.kuka.roboticsAPI.geometricModel.math.Vector;
import com.kuka.roboticsAPI.geometricModel.math.XyzAbcTransformation;
import com.kuka.roboticsAPI.ioModel.AbstractIOGroup;
import com.kuka.roboticsAPI.ioModel.Input;
import com.kuka.roboticsAPI.ioModel.Output;
import com.kuka.roboticsAPI.persistenceModel.templateModel.FrameTemplate;
import com.kuka.roboticsAPI.persistenceModel.templateModel.ToolTemplate;


public final class FeedbackCollector
{
	private static double iiwaLength[] =
	{ 184, 184, 216, 184, 216, 126, 26 };
	private static double coords[][] =
	{
	{ 0, 0, 0 },
	{ 0, 0, 156 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 },
	{ 0, 0, 0 }, };
	
	private static double cs[][][] = new double[9][4][4];
	
	private static Matrix orient[] = new Matrix[8];
	
	public static class FrameData
	{
		public String name = "";
		public FrameTemplate frame = null;
		public ObjectFrame frameObj = null;
	}
	
	public static class PointData
	{
	    public String name; 
	    public List<Double> coords;  
	    public List<Double> orient;
	    public double E1 = 0;
	    public int status = 0;
	    public int turn = 0;
	    public Boolean flagE1 = false;
	    public Boolean flagStatus = false;
	    public Boolean flagTurn = false;
	    public String device;
	    
	    public PointData()
	    {
	    	this.coords=new ArrayList<Double>();
	    	this.orient=new ArrayList<Double>();
	    }
	 };
	
	private static ArrayList<PointData> points; 
	private static ArrayList<FrameData> frames;
	
	private static Matrix getYRot(double angle)
	{
		return Matrix.ofRowFirst(Math.cos(angle), 0, Math.sin(angle), 0, 1, 0,
				-Math.sin(angle), 0, Math.cos(angle));
	}

	private static Matrix getZRot(double angle)
	{
		return Matrix.ofRowFirst(Math.cos(angle), -Math.sin(angle), 0,
				Math.sin(angle), Math.cos(angle), 0, 0, 0, 1);
	}
	
	private static void getCoords(JointPosition pos)
	{
		Matrix test = Matrix.ofRowFirst(1, 0, 0, 0, 1, 0, 0, 0, 1);
		double angle;
		orient[0] = new MatrixBuilder(test).toMatrix();
		
		for (int i=0; i<9; i++)
		{
			for (int j=0; j<4; j++)
			{
				for (int k=0; k<4; k++)
				{
					if (j!=k)
						cs[i][j][k]=0;
					else
						cs[i][j][k]=1;
				}
			}
		}
		
		cs[1][2][3] = 156;
		
		for (int i = 0; i < 7; i++)
		{
			angle = pos.get(i);
			Vector vector = Vector.of(0, 0, iiwaLength[i]);

			if (i == 3)
				angle = -angle;
			if (i % 2 == 1)
				test = test.multiply(getYRot(angle));
			else
				test = test.multiply(getZRot(angle));
			orient[1+i] = new MatrixBuilder(test).toMatrix();
			vector = test.multiply(vector);
			for (int j=0; j<3; j++)
			{
				for (int k=0; k<3; k++)
				{
					cs[2+i][j][k]=test.get(j, k);
				}
			}
			for (int j = 0; j < 3; j++)
			{
				coords[2 + i][j] = coords[1 + i][j] + vector.get(j);
			}
		}
		
		for (int i=2; i<9; i++)
		{
			for (int j=0; j<3; j++)
			{
				cs[i][j][3]=coords[i][j];
			}
		}
	}
	
	public static int getForce(LBR iiwa, ByteBuffer buffer)
	{
		Vector force = iiwa.getExternalForceTorque(iiwa.getFlange()).getForce();
		for (int i = 0; i < 3; i++)
		{
			buffer.putDouble(force.get(i));
		}
		return 3;
	}
	
	public static int getForceTool(LBR iiwa, ByteBuffer buffer, ObjectFrame eef)
	{
		Vector force = iiwa.getExternalForceTorque(eef).getForce();
		for (int i = 0; i < 3; i++)
		{
			buffer.putDouble(force.get(i));
		}
		return 3;
	}
	
	
	public static int getJointAngels(LBR iiwa, ByteBuffer buffer)
	{
		JointPosition pos = iiwa.getCurrentJointPosition();
		for (int i = 0; i < 7; i++)
		{
			buffer.putDouble(pos.get(i));
		}
		return 7;
	}
	
	public static int getEefCoords(LBR iiwa, ObjectFrame eef, ByteBuffer buffer)
	{
		Frame frame = iiwa.getCurrentCartesianPosition(eef);
		buffer.putDouble(frame.getX());
		buffer.putDouble(frame.getY());
		buffer.putDouble(frame.getZ());
		buffer.putDouble(frame.getAlphaRad());
		buffer.putDouble(frame.getBetaRad());
		buffer.putDouble(frame.getGammaRad());
		LBRE1Redundancy redun = new LBRE1Redundancy(frame.getRedundancyInformation().get("KUKA_Sunrise_Cabinet_1/LBR_iiwa_7_R800").getAllParameters());
		buffer.putDouble(redun.getE1());
		buffer.putInt(redun.getStatus());
		buffer.putInt(redun.getTurn());
		return 6+7+1+2;
	}
	

	public static int getDebugCoords(LBR iiwa, ByteBuffer buffer)
	{
		Frame frame = iiwa.getCurrentCartesianPosition(iiwa.getFlange());
		JointPosition pos = iiwa.getCurrentJointPosition();
		buffer.putDouble(frame.getX());
		buffer.putDouble(frame.getY());
		buffer.putDouble(frame.getZ());
		buffer.putDouble(frame.getAlphaRad());
		buffer.putDouble(frame.getBetaRad());
		buffer.putDouble(frame.getGammaRad());
		LBRE1Redundancy redun = new LBRE1Redundancy(frame.getRedundancyInformation().get("KUKA_Sunrise_Cabinet_1/LBR_iiwa_7_R800").getAllParameters());
		buffer.putDouble(redun.getE1());
		buffer.putInt(redun.getStatus());
		buffer.putInt(redun.getTurn());
		for (int i=0; i<7; i++)
		{
			buffer.putDouble(pos.get(i));
		}
		return 6+7+1+2;
	}
	
	public static int getCoordinates(LBR iiwa, ByteBuffer buffer)
	{
		JointPosition pos = iiwa.getCurrentJointPosition();
		getCoords(pos);

		for (int i = 0; i < 9; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				buffer.putDouble(coords[i][j]);
			}
		}
		return 3*9;
	}
	
	public static int getJointCs(LBR iiwa, ByteBuffer buffer)
	{
		JointPosition pos = iiwa.getCurrentJointPosition();
		getCoords(pos);
		for (int i = 0; i < 9; i++)
		{
			for (int j = 0; j < 4; j++)
			{
				for (int k = 0; k < 4; k++)
				{
					buffer.putDouble(cs[i][j][k]);
				}
			}
		}
		
		return 9 * 4 * 4;
	}
	
	public static int getForwardKinematics(LBR iiwa, ByteBuffer buffer, ArrayList<Double> angles)
	{
		JointPosition joints = new JointPosition(7);
		for (int i=0; i<7; i++)
			joints.set(i, angles.get(i));
		
		getCoords(joints);
		
		for (int i = 0; i < 9; i++)
			for (int j = 0; j < 4; j++)
				for (int k = 0; k < 4; k++)
					buffer.putDouble(cs[i][j][k]);
		
		return 9 * 4 * 4;
	}
	
	public static int getFramesOfCurrentTool(ByteBuffer buffer, LBR iiwa, ObjectFrame eef)
	{
		frames = new ArrayList<FeedbackCollector.FrameData>();
		if (!eef.getName().equals(iiwa.getFlange().getName()))
		{
			while (true)
			{
				if (!eef.getParent().getName().equals(iiwa.getFlange().getName()))
				{
					eef = eef.getParent();
				}
				else
					break;
			}
			for (ObjectFrame frame : eef.getChildren())
			{
				GetFramesOfCurrentToolList(iiwa, frame, "");
			}
			for (FrameData frame : frames)
			{
				buffer.putInt(frame.name.length());
				buffer.put(frame.name.getBytes());
				buffer.putDouble(frame.frameObj.getX());
				buffer.putDouble(frame.frameObj.getY());
				buffer.putDouble(frame.frameObj.getZ());
				buffer.putDouble(frame.frameObj.getAlphaRad());
				buffer.putDouble(frame.frameObj.getBetaRad());
				buffer.putDouble(frame.frameObj.getGammaRad());
				//buffer.putDouble(frame.frame.getAdditionalInformation().getInfo())
			}
			
			return frames.size();
		}
		else
			return 0;
	}
	
	public static void GetFramesOfCurrentToolList(LBR iiwa, ObjectFrame eef, String name)
	{
		FrameData temp = new FrameData();
		temp.name = name + "/" + eef.getName();
		temp.frameObj = eef;
		frames.add(temp);
		for (ObjectFrame frame : eef.getChildren())
		{
			GetFramesOfCurrentToolList(iiwa, frame, temp.name);
		}
	}
	
	public static int getFramesOfTool(ByteBuffer buffer, String tool, List<ToolTemplate> ToolTemplates)
	{
		frames = new ArrayList<FeedbackCollector.FrameData>();
		for (ToolTemplate toolObj : ToolTemplates)
		{
			if (!toolObj.getName().equals(tool))
				continue;
			GetToolFrame(toolObj.getFrames().getFrame(), "");
		}
		for (FrameData frame : frames)
		{
			buffer.putInt(frame.name.length());
			buffer.put(frame.name.getBytes());
			buffer.putDouble(frame.frame.getTransformation().getX());
			buffer.putDouble(frame.frame.getTransformation().getY());
			buffer.putDouble(frame.frame.getTransformation().getZ());
			buffer.putDouble(frame.frame.getTransformation().getA());
			buffer.putDouble(frame.frame.getTransformation().getB());
			buffer.putDouble(frame.frame.getTransformation().getC());
			//buffer.putDouble(frame.frame.getAdditionalInformation().getInfo())
		}
		
		return frames.size();
	}
	
	private static int GetToolFrame(List<FrameTemplate> interFrame, String name)
	{
		for (FrameTemplate frame : interFrame)
		{
			if (frame.getClass().getName() == "com.kuka.roboticsAPI.persistenceModel.templateModel.FrameTemplate")
			{
				FrameData temp = new FrameData();
				temp.name = name + "/" + frame.getName();
				temp.frame = frame;
				frames.add(temp);
				if (frame.getFrames() != null)
					GetToolFrame(frame.getFrames().getFrame(), name + "/" + frame.getName());
			}
		}
		return 0;
	}
	
	public static int getInverseKinematics(LBR iiwa, ByteBuffer buffer, ArrayList<Double> data, byte useJointPos)
	{
		XyzAbcTransformation transformation = XyzAbcTransformation.ofRad(data.get(0),
				data.get(1),data.get(2),data.get(3),data.get(4),data.get(5));
		JointPosition ik;
		if (useJointPos>0)
		{
			if (useJointPos==1)
			{
				JointPosition joints = new JointPosition(7);
				for (int i=0; i<7; i++)
				{
					joints.set(i, data.get(i+6));
				}
				ik = iiwa.getInverseKinematic(transformation, joints);
			}
			else if (useJointPos==2)
				ik = iiwa.getInverseKinematic(transformation, iiwa.getCurrentJointPosition());
			else
				throw new IllegalArgumentException();
		}
		else if (useJointPos==0)
			ik = iiwa.getInverseKinematic(transformation, null);
		else
			throw new IllegalArgumentException();
		
		for (int i=0; i<7; i++)
		{
			buffer.putDouble(ik.get(i));
		}
		
		return 7;
	}
	
	public static int getTransformationEefVector(LBR iiwa, ObjectFrame eef, Boolean toolConnected, ByteBuffer buffer)
	{
		if (iiwa.getFlange().getName().equals(eef.getName()))
		{ 
			for (int i=0; i<3; i++)
				buffer.putDouble(0);
		}
		else
		{
			XyzAbcTransformation res = GetTransformationEefMatrix(iiwa, eef);
			buffer.putDouble(res.getX());
			buffer.putDouble(res.getY());
			buffer.putDouble(res.getZ());
		}
		
		return 3;
	}
	
	public static XyzAbcTransformation GetTransformationEefMatrix(LBR iiwa, ObjectFrame eef)
	{
		if (!eef.getParent().getName().equals(iiwa.getFlange().getName()))
		{
			XyzAbcTransformation transMatrix = GetTransformationEefMatrix(iiwa, eef.getParent());
			transMatrix = XyzAbcTransformation.of(transMatrix.compose(
					XyzAbcTransformation.ofRad(
							eef.getX(),eef.getY(),eef.getZ(),
							eef.getAlphaRad(),eef.getBetaRad(),eef.getGammaRad()
							)));
			return transMatrix;
		}
		else
			return XyzAbcTransformation.of(eef.getTransformationFromParent());
	}

	public static int getTransformationEefAngle(LBR iiwa, ObjectFrame eef, Boolean toolConnected, ByteBuffer buffer)
	{
		if (iiwa.getFlange().getName().equals(eef.getName()))
		{
			for (int i=0; i<3; i++)
				buffer.putDouble(0);
		}
		else
		{
			XyzAbcTransformation res = GetTransformationEefMatrix(iiwa, eef);
			buffer.putDouble(res.getAlphaRad());
			buffer.putDouble(res.getBetaRad());
			buffer.putDouble(res.getGammaRad());
		}
		
		return 3;
	}
	
	public static int getInverseKinematicsFromRed(LBR iiwa, ByteBuffer buffer, ArrayList<Double> data, double E1, int status, int turn)
	{
		Frame target = new Frame(data.get(0), data.get(1), data.get(2),
				data.get(3), data.get(4), data.get(5));
		LBRE1Redundancy red = new LBRE1Redundancy();
		red.setE1(E1);
		red.setStatus(status);
		red.setTurn(turn);
		target.setRedundancyInformation(iiwa, red);
		JointPosition ik;
		ik = iiwa.getInverseKinematicFromFrameAndRedundancy(target);
		
		for (int i=0; i<7; i++)
		{
			buffer.putDouble(ik.get(i));
		}
		
		return 7;
	}
	
	public static int getIoData(ServerConfig config, ByteBuffer buffer)
	{
		int writed=0;
		buffer.putInt(config.IoGroups.size());
		for (AbstractIOGroup io: config.IoGroups)
		{
			buffer.putInt(io.getIOGroupName().length());
			writed+=4;
			buffer.put(io.getIOGroupName().getBytes());
			writed+=io.getIOGroupName().length();
			buffer.putInt(io.getInputs().size());
			writed+=4;
			for (Input input: io.getInputs())
			{
				buffer.putInt(input.getIOName().length());
				writed+=4;
				
				buffer.put(input.getIOName().getBytes());
				writed+=input.getIOName().length();
				
				switch (input.getDataType())
				{
					case ANALOG:
						buffer.put((byte) 0);
						break;
					case BOOLEAN:
						buffer.put((byte) 1);
						break;
					case INTEGER:
						buffer.put((byte) 2);
						break;
					case UNSIGNED_INTEGER:
						buffer.put((byte) 3);
						break;
				}
				writed+=1;
			}
			buffer.putInt(io.getOutputs().size());
			writed+=4;
			for (Output output: io.getOutputs())
			{
				buffer.putInt(output.getIOName().length());
				writed+=4;
				
				buffer.put(output.getIOName().getBytes());
				writed+=output.getIOName().length();
				
				switch (output.getDataType())
				{
					case ANALOG:
						buffer.put((byte) 0);
						break;
					case BOOLEAN:
						buffer.put((byte) 1);
						break;
					case INTEGER:
						buffer.put((byte) 2);
						break;
					case UNSIGNED_INTEGER:
						buffer.put((byte) 3);
						break;
				}
				writed+=1;
			}
		}
		
		return writed;
	}
	
	public static int getSavedPoints(LBR iiwa, ByteBuffer buffer)
	{
		points = new ArrayList<PointData>();
		getFrames(World.Current.getRootFrame().getChildren(), "", iiwa);
		for (PointData point : points)
		{
			buffer.putInt(point.name.length());
			buffer.put(point.name.getBytes());
			buffer.putInt(point.device.length());
			buffer.put(point.device.getBytes());
			for (Double coord : point.coords)
				buffer.putDouble(coord);
			for (Double orient : point.orient)
				buffer.putDouble(orient);
			if (point.flagE1)
			{
				buffer.put((byte)1);
				buffer.putDouble(point.E1);
			}
			else
				buffer.put((byte)0);
			
			if (point.flagStatus)
			{
				buffer.put((byte)1);
				buffer.putInt(point.status);
			}
			else
				buffer.put((byte)0);
			
			if (point.flagTurn)
			{
				buffer.put((byte)1);
				buffer.putInt(point.turn);
			}
			else
				buffer.put((byte)0);
		}
		return points.size();
	}
	
	public static int getNames(LBR iiwa, ByteBuffer buffer, int command)
	{
		int writed=0;
		if (command == 0)
		{
			buffer.put(iiwa.getController().getName().getBytes());
			writed = iiwa.getController().getName().length();
		}
		else
		{
			buffer.put(iiwa.getName().getBytes());
			writed = iiwa.getName().length();
		}
		return writed;
	}
	
	public static int getToolNames(ServerConfig config, ByteBuffer buffer)
	{
		String tools = "";
		for (ToolTemplate tool: config.ToolTemplates)
		{
			tools = tools.concat(tool.getName());
			tools = tools.concat(" ");
		}
		tools = tools.substring(0,tools.length()-1);
		buffer.put(tools.getBytes());
		return tools.length();
	}
	
	public static int getCurrentTool(boolean toolIsConnected, Tool tool, ByteBuffer buffer)
	{
		int writed=0;
		if (toolIsConnected)
		{
			writed = tool.getName().length();
			buffer.put(tool.getName().getBytes());
		}
		
		return writed;
	}
	
	private static int getFrames(List<ObjectFrame> interFrame, String name, LBR iiwa)
	{
		for (ObjectFrame frame : interFrame)
		{
			if (frame.getClass().getName() == "com.kuka.roboticsAPI.persistenceModel.PersistentFrame")
			{
				PointData temp;
				Object[] keyArr = frame.getRedundancyInformation().keySet().toArray();
				if (keyArr.length==0)
				{
					temp = new PointData();
					temp.name=name + "/" + 
							frame.toString().substring(0,frame.toString().indexOf(' '));
					temp.coords.add(frame.getX());
					temp.coords.add(frame.getY());
					temp.coords.add(frame.getZ());
					temp.orient.add(frame.getAlphaRad());
					temp.orient.add(frame.getBetaRad());
					temp.orient.add(frame.getGammaRad()); 
					temp.device="";
					points.add(temp);
				}
				else
				{
					for (Object keyObj: keyArr)
					{
						String key = (String) keyObj; 
						temp = new PointData();
						temp.name=name + "/" + 
								frame.toString().substring(0,frame.toString().indexOf(' '));
						temp.coords.add(frame.getX());
						temp.coords.add(frame.getY());
						temp.coords.add(frame.getZ());
						temp.orient.add(frame.getAlphaRad());
						temp.orient.add(frame.getBetaRad());
						temp.orient.add(frame.getGammaRad()); 
						temp.device=key; 
						try{
							IParameterSet paramSet = frame.getRedundancyInformation(). 
									get(key).getAllParameters();
							if (!paramSet.isEmpty())
							{
								LBRE1Redundancy test = new LBRE1Redundancy(paramSet);
								try{
									temp.E1 = test.getE1();
									temp.flagE1 = true;
								}
								catch (IllegalStateException e){}
								try{
									temp.status=test.getStatus();
									temp.flagStatus = true;
								}
								catch (IllegalStateException e){}
								try{
									temp.turn=test.getTurn(); 
									temp.flagTurn = true;
								}
								catch (IllegalStateException e){}
							}
						}
						catch (ClassCastException e)
						{
						}
						points.add(temp);
					}
				}
	
				getFrames(
						frame.getChildren(),
						name+ "/"+ frame.toString().
						substring(0,frame.toString().indexOf(' ')), iiwa
						);
			}
		}
		return 0;
	}

}