package application;

import static com.kuka.roboticsAPI.motionModel.BasicMotions.*;

import java.io.EOFException;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.nio.BufferUnderflowException;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Set;

import serverUtils.FeedbackCollector;
import serverUtils.ServerConfig;
import serverUtils.ServerUtils;
import sun.reflect.generics.reflectiveObjects.NotImplementedException;

import com.kuka.roboticsAPI.applicationModel.RoboticsAPIApplication;
import com.kuka.roboticsAPI.controllerModel.Controller;
import com.kuka.roboticsAPI.deviceModel.JointPosition;
import com.kuka.roboticsAPI.deviceModel.LBR;
import com.kuka.roboticsAPI.executionModel.CommandInvalidException;
import com.kuka.roboticsAPI.geometricModel.ITransformationProvider;
import com.kuka.roboticsAPI.geometricModel.LoadData;
import com.kuka.roboticsAPI.geometricModel.ObjectFrame;
import com.kuka.roboticsAPI.geometricModel.Tool;
import com.kuka.roboticsAPI.geometricModel.World;
import com.kuka.roboticsAPI.geometricModel.math.XyzAbcTransformation;
import com.kuka.roboticsAPI.motionModel.IMotionContainer;
import com.kuka.roboticsAPI.motionModel.RobotMotion;
import com.kuka.roboticsAPI.motionModel.SplineJP;
import com.kuka.roboticsAPI.motionModel.SplineMotionCP;
import com.kuka.roboticsAPI.motionModel.SplineMotionJP;
import com.kuka.roboticsAPI.motionModel.controlModeModel.PositionControlMode;
import com.kuka.roboticsAPI.persistenceModel.PersistenceException;
import com.kuka.roboticsAPI.persistenceModel.templateModel.ToolTemplate;

/**
 * Implementation of a robot application.
 * <p>
 * The application provides a {@link RoboticsAPITask#initialize()} and a
 * {@link RoboticsAPITask#run()} method, which will be called successively in
 * the application lifecycle. The application will terminate automatically after
 * the {@link RoboticsAPITask#run()} method has finished or after stopping the
 * task. The {@link RoboticsAPITask#dispose()} method will be called, even if an
 * exception is thrown during initialization or run.
 * <p>
 * <b>It is imperative to call <code>super.dispose()</code> when overriding the
 * {@link RoboticsAPITask#dispose()} method.</b>
 * 
 * @see #initialize()
 * @see #run()
 * @see #dispose()
 */
public class KukaLbrToolbox extends RoboticsAPIApplication
{
	private Controller ksc;
	private LBR iiwa;

	private ServerSocketChannel serverSocketChannel = null;
	private ServerSocket serverSocket = null;
	private static Selector serverSelector;
	private InetSocketAddress serverAddr = null;
	private int ops;
	private ByteBuffer buffer = ByteBuffer.allocate(65536);

	private Tool tool;
	private Boolean toolIsConnected = false;
	private ObjectFrame currentEEF;

	private IMotionContainer motionHandle;

	private ServerConfig serverConfig;

	private enum ResponseType{
		DFF,
		DJC,
		DJV,
		DTA,
		IPD,
		IIO,
		ITN,
		INN,
		CTC,
		DPE,
		DPD,
		ITA,
		ITV
	}
	
	public void initialize()
	{
		iiwa = getContext().getDeviceFromType(LBR.class);
		iiwa.setESMState("1");	
		ksc = iiwa.getController();
		currentEEF = iiwa.getFlange();
		serverConfig = new ServerConfig(ksc);
		serverConfig.InitParams(ksc.getContext());
	}

	@Override
	public void dispose()
	{
		try
		{
			serverSocketChannel.close();
		}
		catch (IOException e)
		{
			e.printStackTrace();
		}
		try
		{
			serverSocket.close();
		}
		catch (IOException e)
		{
			e.printStackTrace();
		}
		try
		{
			serverSelector.close();
		}
		catch (IOException e)
		{
			e.printStackTrace();
		}
		finally
		{
			super.dispose();
		}
	}

	public void run()
	{
		if (serverStart(serverConfig.DefaultTcpPort))
		{
			System.out.println("Server started!");
			try
			{
				while (true)
				{
					serverSelector.select();
					Set<SelectionKey> selectedKeys = serverSelector
							.selectedKeys();
					Iterator<SelectionKey> i = selectedKeys.iterator();

					while (i.hasNext())
					{
						SelectionKey key = i.next();

						if (key.isReadable())
						{
							handleRead(key);
						}
						else if (key.isAcceptable())
						{
							handleAccept(serverSocketChannel, key);
						}
						i.remove();
					}
				}
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
		}
		else
		{
			System.out.println("Server startup failed!");
		}
	}

	public boolean serverStart(int portNumber)
	{
		try
		{
			serverSelector = Selector.open();
			serverSocketChannel = ServerSocketChannel.open();
			serverSocket = serverSocketChannel.socket();
			serverAddr = new InetSocketAddress(portNumber);
			serverSocket.bind(serverAddr);
			serverSocketChannel.configureBlocking(false);
			ops = serverSocketChannel.validOps();
			serverSocketChannel.register(serverSelector, ops, null);
		}
		catch (IOException e)
		{
			System.out.println("Error during server starting-up!");
			e.printStackTrace();
			return false;
		}
		return true;
	}

	private void handleAccept(ServerSocketChannel mySocket, SelectionKey key)
			throws IOException
	{
		mySocket.socket().setReceiveBufferSize(65536);
		SocketChannel client = mySocket.accept();
		client.socket().setReceiveBufferSize(65536);
		client.socket().setSendBufferSize(65536);
		client.configureBlocking(false);
		System.out.println("Connection Accepted...");
		client.register(serverSelector, SelectionKey.OP_READ);
	}

	private void handleRead(SelectionKey key) throws IOException
	{
		SocketChannel client = (SocketChannel) key.channel();
		buffer.clear();
		int read = client.read(buffer);

		if (read <= 0)
		{
			client.close();
			key.cancel();
			System.out.println("Connection closed...");
			return;
		}

		parseCommand(client);
	}

	private void parseCommand(SocketChannel client)
	{
		try
		{
			buffer.flip();
			byte ch = buffer.get();
			if (ch == '<')
			{
				ch = buffer.get();
				switch (ch)
				{
				case 'D':
					parseDataCommand(client);
					break;
				case 'M':
					parseMoveCommand(client);
					break;
				case 'C':
					parseControlCommand(client);
					break;
				case 'I':
					parseInfoCommand(client);
					break;
				default:
					sendMsg(client, "<EIC"); // Invalid command
					break;
				}
			}
			else
			{
				sendMsg(client, "<EED"); // Empty Data
			}
		}
		catch (EOFException e)
		{
			sendMsg(client, "<EED"); // Empty Data
			e.printStackTrace();
		}
		catch (IOException e)
		{
			sendMsg(client, "<EIO"); // IO error
			e.printStackTrace();
		}
		catch (IllegalStateException e)
		{
			sendMsg(client, "<ESE"); // Error State
			e.printStackTrace();
		}
		catch (IllegalArgumentException e)
		{
			sendMsg(client, "<EAE"); // Invalid Argument
			e.printStackTrace();
		}
		catch (NotImplementedException e)
		{
			sendMsg(client, "<ENI"); // Not implemented
			e.printStackTrace();
		}
		catch (BufferUnderflowException e)
		{
			sendMsg(client, "<EED"); // Empty Data
			e.printStackTrace();
		}
		catch (NullPointerException e)
		{
			sendMsg(client, "<ENP"); // Null pointer provided
			e.printStackTrace();
		}
		catch (PersistenceException e)
		{
			sendMsg(client, "<ENF"); // Object not found
			e.printStackTrace();
		}
		catch (CommandInvalidException e)
		{
			sendMsg(client, "<EIC"); // Command invalid
			e.printStackTrace();
		}
	}

	private void parseMoveCommand(SocketChannel client) throws IOException,
			IllegalStateException, IllegalArgumentException, EOFException,
			NotImplementedException, BufferUnderflowException,
			NullPointerException, CommandInvalidException
	{
		byte mode = buffer.get();
		int size = buffer.getInt();
		SplineMotionCP<?>[] spMotions = null;
		RobotMotion<?>[] btMotions = null;
		SplineMotionJP<?>[] spMotionsJp = null; // J
		if (mode == 'B')
			btMotions = new RobotMotion<?>[size];
		else if (mode == 'S')
			spMotions = new SplineMotionCP<?>[size];
		else if (mode == 'J')
			spMotionsJp = new SplineMotionJP<?>[size];
		else
			throw new IllegalArgumentException();
		// TODO PARSER CIRC
		ArrayList<Double> motionData = new ArrayList<Double>();

		double accel = 0;
		double vel = 0;
		byte moveType = 0;
		int flags = 0;
		byte dataCount = 0;

		for (int i = 0; i < size; i++)
		{
			moveType = buffer.get();
			flags = buffer.getInt();
			dataCount = (byte) (moveType & 15); // &0000 1111
			motionData.clear();

			for (int j = 0; j < dataCount; j++)
				motionData.add(buffer.getDouble());

			moveType = (byte) (moveType & 240); // &1111 0000 // THIS IS INT8,
												// NOT UINT8

			switch (moveType)
			{
			case 32 - 128:
			case 48 - 128:
			case 64 - 128:
				// rellin // relSpl // relCirc ???
				if (mode == 'B')
					btMotions[i] = ServerUtils.GetNewSplinePoint(motionData,
							dataCount, moveType);
				else if (mode == 'S')
					spMotions[i] = ServerUtils.GetNewSplinePoint(motionData,
							dataCount, moveType);
				else
					throw new IllegalArgumentException();
				break;
			case 16:
				if (mode == 'B')
					btMotions[i] = ptp(ServerUtils.GetNewFrame(motionData, 0));
				else if (mode == 'J')
				{
					JointPosition jp = new JointPosition(7);
					for (int jj = 0; jj < 7; jj++)
						jp.set(jj, motionData.get(jj));
					spMotionsJp[i] = ptp(jp);
				}
				else
					throw new IllegalArgumentException();
				break;
			case 32:
				if (mode == 'B')
					btMotions[i] = lin(ServerUtils.GetNewFrame(motionData, 0));
				else if (mode == 'S')
					spMotions[i] = lin(ServerUtils.GetNewFrame(motionData, 0));
				else
					throw new IllegalArgumentException();
				break;
			case 48:
				if (mode == 'B')
					btMotions[i] = spl(ServerUtils.GetNewFrame(motionData, 0));
				else if (mode == 'S')
					spMotions[i] = spl(ServerUtils.GetNewFrame(motionData, 0));
				else
					throw new IllegalArgumentException();
				break;
			case 64:
				if (mode == 'B')
					btMotions[i] = circ(ServerUtils.GetNewFrame(motionData, 0),
							ServerUtils.GetNewFrame(motionData, 6));
				else if (mode == 'S')
					spMotions[i] = circ(ServerUtils.GetNewFrame(motionData, 0),
							ServerUtils.GetNewFrame(motionData, 6));
				else
					throw new IllegalArgumentException();
				break;
			default:
				throw new IllegalArgumentException();
			}

			if (flags > 0)
			{
				if ((flags & 1 << 0) != 0)
				{
					accel = buffer.getDouble();

					if (mode == 'B')
						btMotions[i].setJointAccelerationRel(accel);
					else if (mode == 'S')
						spMotions[i].setJointAccelerationRel(accel);
					else if (mode == 'J')
						spMotionsJp[i].setJointAccelerationRel(accel);
					else
						throw new IllegalArgumentException();
				}
				if ((flags & 1 << 1) != 0)
				{
					vel = buffer.getDouble();
					if (mode == 'B')
						btMotions[i].setJointVelocityRel(vel);
					else if (mode == 'S')
						spMotions[i].setJointVelocityRel(vel);
					else if (mode == 'J')
						spMotionsJp[i].setJointVelocityRel(vel);
					else
						throw new IllegalArgumentException();
				}
				if ((flags & 1 << 2) != 0)
				{
					throw new NotImplementedException();
				}
				if ((flags & 1 << 3) != 0)
				{
					throw new NotImplementedException();
				}
			}
		}

		if (mode == 'B')
			motionHandle = currentEEF.move(batch(btMotions));
		else if (mode == 'S')
			motionHandle = currentEEF.move(spline(spMotions));
		else
			motionHandle = currentEEF.move(new SplineJP(spMotionsJp));
		if (!motionHandle.hasError())
		{
			motionHandle.cancel();
			motionHandle = null;
			sendMsg(client, "<OKK");
		}
		else
		{
			motionHandle.cancel();
			motionHandle = null;
			throw new IllegalStateException();
		}
	}

	private void parseInfoCommand(SocketChannel client) throws IOException,
			BufferUnderflowException, IllegalArgumentException
	{
		byte ch = buffer.get();
		switch (ch)
		{
		case 'P':
			dataTransmit(0, "<IPD", client);
			break;
		case 'I':
			dataTransmit(0, "<IIO", client);
			break;
		case 'N':
			ch = buffer.get();
			if (ch == 'C')
				dataTransmit(0, "<INN", client);
			else if (ch == 'R')
				dataTransmit(1, "<INN", client);
			else if (ch == 'T')
				dataTransmit(0, "<ITN", client);
			else
				throw new IllegalArgumentException();
			break;
		case 'T':
			ch = buffer.get();
			if (ch == 'A')
			{
				dataTransmit(0, "<ITA", client);
			}
			else if (ch == 'V')
			{
				dataTransmit(0, "<ITV", client);
			}
			else
				throw new IllegalArgumentException();
			break;
		default:
			throw new IllegalArgumentException();
		}
	}

	private void parseDataCommand(SocketChannel client) throws IOException,
			BufferUnderflowException, IllegalArgumentException
	{
		byte ch = buffer.get();
		switch (ch)
		{
		case 'P':
			ch = buffer.get();
			switch (ch)
			{
			case 'A':
				dataTransmit(0, "<DTA", client);
				break;
			case 'J':
				ch = buffer.get();
				if (ch == 'V')
					dataTransmit(0, "<DJV", client);
				else if (ch == 'C')
					dataTransmit(0, "<DJC", client);
				else
					throw new IllegalArgumentException();
				break;
			case 'F':
				ch = buffer.get();
				if (ch == 'F')
					dataTransmit(0, "<DFF", client);
				else if (ch == 'T')
					dataTransmit(1, "<DFF", client);
				else
					throw new IllegalArgumentException();
				break;
			case 'D':
				dataTransmit(1, "<DPD", client);
				break;
			case 'E':
				dataTransmit(0, "<DPE", client);
				break;
			default:
				throw new IllegalArgumentException();
			}
			break;
		case 'K':
			String begin;
			ch = buffer.get();
			if (ch == 'F')
			{
				begin = "<DKF";
				ArrayList<Double> data = new ArrayList<Double>();
				for (int i = 0; i < 7; i++)
					data.add(buffer.getDouble());
				buffer.clear();
				buffer.put(begin.getBytes(), 0, begin.length());
				buffer.putInt(0);
				int writed = FeedbackCollector.getForwardKinematics(iiwa,
						buffer, data);
				buffer.putInt(begin.length(), writed);
				buffer.flip();
				client.write(buffer);
			}
			else if (ch == 'I')
			{
				begin = "<DKI";
				ArrayList<Double> data = new ArrayList<Double>();
				for (int i = 0; i < 6; i++)
					data.add(buffer.getDouble());

				byte useJointPos = buffer.get();
				if (useJointPos == 1)
					for (int i = 0; i < 7; i++)
						data.add(buffer.getDouble());
				byte useRedundancy = buffer.get();
				int writed = 0;
				if (useRedundancy == 1)
				{
					double E1 = buffer.getDouble();
					int status = buffer.getInt();
					int turn = buffer.getInt();
					buffer.clear();
					buffer.put(begin.getBytes(), 0, begin.length());
					buffer.putInt(0);
					writed = FeedbackCollector.getInverseKinematicsFromRed(
							iiwa, buffer, data, E1, status, turn);
				}
				else
				{
					buffer.clear();
					buffer.put(begin.getBytes(), 0, begin.length());
					buffer.putInt(0);
					writed = FeedbackCollector.getInverseKinematics(iiwa,
							buffer, data, useJointPos);
				}

				buffer.putInt(begin.length(), writed);
				buffer.flip();
				client.write(buffer);
			}
			else
				throw new IllegalArgumentException();
			break;
		default:
			throw new IllegalArgumentException();
		}
	}

	private void parseControlCommand(SocketChannel client) throws IOException,
			BufferUnderflowException, PersistenceException
	{
		byte ch = buffer.get();
		switch (ch)
		{
		case 'C':
			ch = buffer.get();
			if (ch == 'C') // Control: Connection Check
				sendMsg(client, "<CCR"); // Control: Connection Receive
			else
				throw new IllegalArgumentException();
			break;
		case 'T':
			ch = buffer.get();
			switch (ch)
			{
			case 'D':
				if (toolIsConnected)
				{
					tool.detach();
					toolIsConnected = false;
					tool = null;
					currentEEF = iiwa.getFlange();
					sendMsg(client, "<OKK");
				}
				else
				{
					sendMsg(client, "<ECE");
				}
				break;
			case 'A':
				if (!toolIsConnected)
				{
					int size = buffer.getInt();
					ArrayList<Character> name = new ArrayList<Character>();
					for (int i = 0; i < size; i++)
						name.add((char) buffer.get());
					String nameStr = getStringRepresentation(name);
					tool = getApplicationData().createFromTemplate(nameStr);
					tool.attachTo(iiwa.getFlange());
					toolIsConnected = true;
					currentEEF = tool.getDefaultMotionFrame();
					sendMsg(client, "<OKK");
				}
				else
				{
					sendMsg(client, "<ECE");
				}
				break;
			case 'C':
				dataTransmit(0, "<CTC", client);
				break;
			case 'F':
				int size = buffer.getInt(); 
				String toolName = "";
				buffer.clear();
				buffer.put("<CTF".getBytes(), 0, 4);
				buffer.putInt(0);
				int writed =0;
				if (size>0)
				{
					ArrayList<Character> name = new ArrayList<Character>();
					for (int i = 0; i < size; i++)
						name.add((char) buffer.get());
					toolName = getStringRepresentation(name);
					writed = FeedbackCollector.getFramesOfTool(buffer,toolName, serverConfig.ToolTemplates);
				}
				else
				{
					writed = FeedbackCollector.getFramesOfCurrentTool(buffer, iiwa, currentEEF);
				}
				buffer.putInt("<CTF".length(), writed);
				buffer.flip();
				client.write(buffer);
				break;
			case 'S':
				if (toolIsConnected)
				{
					int nameSize = buffer.getInt();
					ArrayList<Character> name = new ArrayList<Character>();
					for (int i = 0; i < nameSize; i++)
						name.add((char) buffer.get());
					String nameStr = getStringRepresentation(name);
					ObjectFrame newEEF = tool.getFrame(nameStr);
					if (newEEF!=null)
					{
						currentEEF = newEEF;
						sendMsg(client, "<OKK");
					}
					else
						throw new IllegalArgumentException();
				}
				else
					sendMsg(client, "<ECE");
				break;
			case 'N':
				if (toolIsConnected == false)
				{
					int nameSize = buffer.getInt();
					ArrayList<Character> name = new ArrayList<Character>();
					for (int i = 0; i < nameSize; i++)
						name.add((char) buffer.get());
					String nameStr = getStringRepresentation(name);
					ArrayList<Double> toolData = new ArrayList<Double>();
					for (int i=0; i<1+3+6; i++) // mass + mass centre + transformation
						toolData.add(buffer.getDouble());
					LoadData loadData = new LoadData();
			        loadData.setMass(toolData.get(0));
			        loadData.setCenterOfMass(toolData.get(1),toolData.get(2),toolData.get(3));
			        Tool tempTool = new Tool(nameStr, loadData);
			        XyzAbcTransformation trans = XyzAbcTransformation.ofRad(
			        		toolData.get(4), toolData.get(5), toolData.get(6), 
			        		toolData.get(7), toolData.get(8), toolData.get(9));
			        
			        ObjectFrame toolTransform = tempTool.addChildFrame("TCP",trans);
			        tempTool.setDefaultMotionFrame(toolTransform);
		
			        tool = tempTool;
			        tool.attachTo(iiwa.getFlange());
			        currentEEF = tool.getDefaultMotionFrame();
			        toolIsConnected = true;
			        sendMsg(client, "<OKK");
				}
				else
					sendMsg(client, "<ECE");
				break;
			default:
				throw new IllegalArgumentException();
			}
			break;
		default:
			throw new IllegalArgumentException();
		}
	}

	private String getStringRepresentation(ArrayList<Character> list)
	{
		StringBuilder builder = new StringBuilder(list.size());
		for (Character ch : list)
		{
			builder.append(ch);
		}
		return builder.toString();
	}

	private void dataTransmit(int command, String begin, SocketChannel client)
			throws IOException, IllegalArgumentException
	{
		buffer.clear();
		buffer.put(begin.getBytes(), 0, 4);
		buffer.putInt(0);
		int writed = 0;
		ResponseType t = ResponseType.valueOf(begin.substring(1,4));
		switch(t)
		{
		case DFF:
			if (command == 0)
				writed = FeedbackCollector.getForce(iiwa, buffer);
			else
				writed = FeedbackCollector.getForceTool(iiwa, buffer,
						currentEEF);
			break;
		case DJC:
			writed = FeedbackCollector.getJointCs(iiwa, buffer); break;
		case DJV:
			writed = FeedbackCollector.getCoordinates(iiwa, buffer); break;
		case DTA:
			writed = FeedbackCollector.getJointAngels(iiwa, buffer); break;
		case IPD:
			writed = FeedbackCollector.getSavedPoints(iiwa, buffer); break;
		case IIO:
			writed = FeedbackCollector.getIoData(serverConfig, buffer); break;
		case ITN:
			writed = FeedbackCollector.getToolNames(serverConfig, buffer); break;
		case INN:
			writed = FeedbackCollector.getNames(iiwa, buffer, command); break;
		case CTC:
			writed = FeedbackCollector.getCurrentTool(toolIsConnected, tool, buffer); break;
		case DPE:
			writed = FeedbackCollector.getEefCoords(iiwa, currentEEF, buffer); break;
		case DPD:
			writed = FeedbackCollector.getDebugCoords(iiwa, buffer); break;
		case ITA:
			writed = FeedbackCollector.getTransformationEefAngle(iiwa, currentEEF, toolIsConnected, buffer); break;
		case ITV:
			writed = FeedbackCollector.getTransformationEefVector(iiwa, currentEEF, toolIsConnected, buffer); break;
		default:
			throw new IllegalArgumentException();
		}
		
		buffer.putInt(begin.length(), writed);
		buffer.flip();
		client.write(buffer);
	}

	private void sendMsg(SocketChannel client, String msg)
	{
		buffer.clear();
		buffer.put(msg.getBytes());
		buffer.flip();
		try
		{
			client.write(buffer);
		}
		catch (IOException e)
		{
			try
			{
				client.close();
			}
			catch (IOException e1)
			{
				e1.printStackTrace();
			}
			e.printStackTrace();
		}
	}

	/**
	 * Auto-generated method stub. Do not modify the contents of this method.
	 */
	public static void main(String[] args)
	{
		KukaLbrToolbox app = new KukaLbrToolbox();
		app.runApplication();
	}
}
