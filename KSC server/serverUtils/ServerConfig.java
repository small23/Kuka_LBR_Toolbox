package serverUtils;

import java.net.URL;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import sun.security.action.GetLongAction;

import com.kuka.generated.ioAccess.*;

import com.kuka.roboticsAPI.RoboticsAPIContext;
import com.kuka.roboticsAPI.controllerModel.Controller;
import com.kuka.roboticsAPI.geometricModel.World;
import com.kuka.roboticsAPI.ioModel.AbstractIOGroup;
import com.kuka.roboticsAPI.persistenceModel.XmlApplicationDataSource;
import com.kuka.roboticsAPI.persistenceModel.templateModel.GeometricObjectTemplate;
import com.kuka.roboticsAPI.persistenceModel.templateModel.TemplateElement;
import com.kuka.roboticsAPI.persistenceModel.templateModel.ToolTemplate;
import com.kuka.roboticsAPI.persistenceModel.templateModel.WorkpieceTemplate;

public class ServerConfig
{
	// 1. Set default TCP port for communication;
	// Allowed ports from 30000 to 30010;
	public int DefaultTcpPort = 30001;
	
	public ServerConfig(Controller controller)
	{
		// 2. Init your IOs here
		// IOidx = new IO_CLASS_NAME(controller);
		// idx = number of IO, from 1 to 5; No more than 1 IO group per 1 IOidx!
		// IO_CLASS_NAME = Class in com.kuka.generated.ioAccess
		// Example:
		// IO1 = new IO1_IOGroup(controller);
		// IO2 = new IO2_IOGroup(controller);
		// IO3 = new IO3_IOGroup(controller);
		// IO4 = new IO4_IOGroup(controller);
		// IO5 = new IO5_IOGroup(controller);
		
		IO1 = new IN_IOGroup(controller);
		IO2 = new OUT_IOGroup(controller);
	}
	
	//END OF PUBLIC ZONE, DO NOT CHANGE ANYTHING BELOW THIS COMMENT!
	public void InitParams(RoboticsAPIContext context)
	{
		IoGroups = new ArrayList<AbstractIOGroup>();
		if (IO1!=null)
			IoGroups.add(IO1);
		if (IO2!=null)
			IoGroups.add(IO2);
		if (IO3!=null)
			IoGroups.add(IO3);
		if (IO4!=null)
			IoGroups.add(IO4);
		if (IO5!=null)
			IoGroups.add(IO5);
		
		if (DefaultTcpPort<30000 || DefaultTcpPort > 30010)
			throw new IllegalArgumentException("Default TCP port out of range (30000 - 30010)!");
		
		ToolTemplates = new ArrayList<ToolTemplate>();
		WorkpieceTemplates = new ArrayList<WorkpieceTemplate>();
		GeometricObjectTemplates = new ArrayList<GeometricObjectTemplate>();
		
		XmlApplicationDataSource dataXmlConfig = new XmlApplicationDataSource();
		URL urlFile = context.getConfigurationFile();
		String url = urlFile.toString();
		String dataUrl = url.substring(0, url.lastIndexOf("/") + 1)
				+ XmlApplicationDataSource.DEFAULT_DATAFILE_NAME;
		dataXmlConfig.open(dataUrl);
		if (dataXmlConfig.isOpen())
		{
			Collection<?> templates = dataXmlConfig.loadAllTemplates();
			for (Object templateObj : templates)
			{
				TemplateElement template = (TemplateElement) templateObj;
				String templateClass = template.getClass().getCanonicalName();
				if (templateClass
						.equals("com.kuka.roboticsAPI.persistenceModel.templateModel.ToolTemplate"))
				{
					ToolTemplate tool = (ToolTemplate) template;
					ToolTemplates.add(tool);
				}
				else if (templateClass
						.equals("com.kuka.roboticsAPI.persistenceModel.templateModel.GeometricObjectTemplate"))
				{
					GeometricObjectTemplate geomObj = (GeometricObjectTemplate) template;
					GeometricObjectTemplates.add(geomObj);
				}
				else if (templateClass
						.equals("com.kuka.roboticsAPI.persistenceModel.templateModel.WorkpieceTemplate"))
				{
					WorkpieceTemplate workpiece = (WorkpieceTemplate) template;
					WorkpieceTemplates.add(workpiece);
				}
			}
			dataXmlConfig.close();
		}
		else
		{
			System.out.println("Warning! Can`t open '" + dataUrl+"'! No tool data provided!");
		}
	}
	
	public List<AbstractIOGroup> IoGroups = null;
	
	public List<ToolTemplate> ToolTemplates = null;
	public List<WorkpieceTemplate> WorkpieceTemplates = null;
	public List<GeometricObjectTemplate> GeometricObjectTemplates = null;
	
	public AbstractIOGroup IO1 = null;
	public AbstractIOGroup IO2 = null;
	public AbstractIOGroup IO3 = null;
	public AbstractIOGroup IO4 = null;
	public AbstractIOGroup IO5 = null;
}
