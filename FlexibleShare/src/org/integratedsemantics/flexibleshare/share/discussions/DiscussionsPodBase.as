package org.integratedsemantics.flexibleshare.share.discussions
{
    import com.esria.samples.dashboard.view.PodContentBase;
    
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    
    import mx.collections.ArrayCollection;
    import mx.controls.Tree;
    import mx.events.FlexEvent;
    import mx.managers.PopUpManager;
    import mx.rpc.AsyncToken;
    import mx.rpc.events.FaultEvent;
    import mx.rpc.events.ResultEvent;
    import mx.rpc.http.HTTPService;
    
    import org.integratedsemantics.flexibleshare.share.discussions.create.CreateTopicView;
    import org.integratedsemantics.flexibleshare.share.discussions.edit.EditTopicView;
    import org.integratedsemantics.flexibleshare.share.rte.RichTextEdit;
    import org.integratedsemantics.flexspaces.control.event.ui.DeleteNodesUIEvent;
    import org.integratedsemantics.flexspaces.control.event.ui.TagsCategoriesUIEvent;
    import org.integratedsemantics.flexspaces.model.AppModelLocator;
    import org.integratedsemantics.flexspaces.model.tree.TreeNode;
    
    import spark.components.Button;
    import spark.components.DropDownList;
    import spark.events.IndexChangeEvent;


    public class DiscussionsPodBase extends PodContentBase
    {               
        public var newDiscussionBtn:Button;
        public var discussionsTree:Tree;
        public var rte:RichTextEdit;
        public var editBtn:Button;
        public var deleteBtn:Button;
        public var tagBtn:Button;
		public var siteListDropDown:DropDownList;		

        [Bindable]
        protected var treeRoot:TreeNode = new TreeNode("Topics", "Topics");

		[Bindable]
		protected var siteList:ArrayCollection = new ArrayCollection();

        private var newTreeNode:TreeNode;
        private var mostActiveTreeNode:TreeNode;
        private var allTreeNode:TreeNode;
        private var myTopicsTreeNode:TreeNode;
                
        private var model:AppModelLocator = AppModelLocator.getInstance();
        
        [Embed(source="images/filetypes/_default.png")]
        private var topicIcon:Class;
        
        private var editView:EditTopicView;
        private var createView:CreateTopicView;
        
        private var site:String;     
        

        public function DiscussionsPodBase()
        {
            super();
        }
                                
        override protected function onCreationComplete(e:FlexEvent):void
        {
            super.onCreationComplete(e);

			// todo: use initial site configured if not empty string or null
            site = properties.@siteUrlName;    

            newTreeNode = new TreeNode("New", "new");
            treeRoot.children.addItem(newTreeNode);

            mostActiveTreeNode = new TreeNode("Most Active", "mostactive");
            treeRoot.children.addItem(mostActiveTreeNode);

            allTreeNode = new TreeNode("All", "all");
            treeRoot.children.addItem(allTreeNode);

            myTopicsTreeNode = new TreeNode("My Topics", "mytopics");
            treeRoot.children.addItem(myTopicsTreeNode);

            discussionsTree.expandChildrenOf(treeRoot, true);       
			
			getSites();			
        }

		
		protected function getSites():void
		{
			var service:HTTPService = new HTTPService;
			service.url = model.ecmServerConfig.urlPrefix + "/api/sites";
			service.resultFormat = "text";
			service.addEventListener(ResultEvent.RESULT, onJSONSites);            
			service.addEventListener(FaultEvent.FAULT, onFault);
			var result:AsyncToken = null;
			var parameters:Object = new Object();
			parameters.alf_ticket = model.userInfo.loginTicket;
			result = service.send(parameters);                  
		}
		
        protected function getNewTopics():void
        {
            var service:HTTPService = new HTTPService;
            service.url = model.ecmServerConfig.urlPrefix + "/api/forum/site/" + site + "/discussions/posts/new";
            service.resultFormat = "text";
            service.addEventListener(ResultEvent.RESULT, onJSONLoadNew);           
            service.addEventListener(FaultEvent.FAULT, onFault);
            var result:AsyncToken = null;
            var parameters:Object = new Object();
            parameters.alf_ticket = model.userInfo.loginTicket;
            parameters.numdays = "10";
            result = service.send(parameters);                       
        }

        protected function getMostActiveTopics():void
        {
            var service:HTTPService = new HTTPService;
            service.url = model.ecmServerConfig.urlPrefix + "/api/forum/site/" + site + "/discussions/posts/hot";
            service.resultFormat = "text";
            service.addEventListener(ResultEvent.RESULT, onJSONLoadMostActive);            
            service.addEventListener(FaultEvent.FAULT, onFault);
            var result:AsyncToken = null;
            var parameters:Object = new Object();
            parameters.alf_ticket = model.userInfo.loginTicket;
            result = service.send(parameters);                  
        }

        protected function getAllTopics():void
        {
            var service:HTTPService = new HTTPService;
            service.url = model.ecmServerConfig.urlPrefix + "/api/forum/site/" + site + "/discussions/posts";
            service.resultFormat = "text";
            service.addEventListener(ResultEvent.RESULT, onJSONLoadAll);            
            service.addEventListener(FaultEvent.FAULT, onFault);
            var result:AsyncToken = null;
            var parameters:Object = new Object();
            parameters.alf_ticket = model.userInfo.loginTicket;
            result = service.send(parameters);                       
        }

        protected function getMyTopics():void
        {
            var service:HTTPService = new HTTPService;
            service.url = model.ecmServerConfig.urlPrefix + "/api/forum/site/" + site + "/discussions/posts/myposts";
            service.resultFormat = "text";
            service.addEventListener(ResultEvent.RESULT, onJSONLoadMyTopics);         
            service.addEventListener(FaultEvent.FAULT, onFault);
            var result:AsyncToken = null;
            var parameters:Object = new Object();
            parameters.alf_ticket = model.userInfo.loginTicket;
            result = service.send(parameters);                       
        }
                
        protected function updateAll():void
        {
            newTreeNode.children.removeAll();
            mostActiveTreeNode.children.removeAll();
            allTreeNode.children.removeAll();
            myTopicsTreeNode.children.removeAll();
            getNewTopics();
            getMostActiveTopics();
            getAllTopics(); 
            getMyTopics();
        }
               
		private function onJSONSites(event:ResultEvent):void
		{
			addSites(event.result);        
		}

		private function onJSONLoadNew(event:ResultEvent):void
        {
            addTopics(event.result, newTreeNode);        
        }

        private function onJSONLoadMostActive(event:ResultEvent):void
        {
            addTopics(event.result, mostActiveTreeNode);                    
        }

        private function onJSONLoadAll(event:ResultEvent):void
        {
            addTopics(event.result, allTreeNode);        
        }

        private function onJSONLoadMyTopics(event:ResultEvent):void
        {
            addTopics(event.result, myTopicsTreeNode);                    
        }

        private function onFault(event:FaultEvent):void
        {
            trace("get topics fault");           
        }
        
		private function addSites(data:Object):void
		{
			var dataStr:String = String(data);
			var obj:Object = JSON.parse(dataStr);      
			siteList.source = obj as Array;
		}		

		private function addTopics(data:Object, parent:TreeNode):void
        {
            var dataStr:String = String(data);
            var obj:Object = JSON.parse(dataStr);      
            var items:Array = obj.items as Array;
            for each (var item:Object in items)
            {
                var topic:Topic = new Topic();
                topic.title = item.title;
                topic.label = topic.title;
                topic.content = item.content;
                topic.nodeRef = item.nodeRef;
                topic.name = item.name;
                topic.id = topic.nodeRef.substr(24);
                parent.children.addItem(topic);
                discussionsTree.setItemIcon(topic, topicIcon, null);       
            }                        
        }
                     
        protected function onTreeChange(event:Event):void
        {
            if (discussionsTree.selectedItem is Topic)
            {
                var topic:Topic = discussionsTree.selectedItem as Topic;
                var content:String = topic.content;
                rte.htmlText = content;
                editBtn.enabled = true;
                deleteBtn.enabled = true;
                tagBtn.enabled = true;                           
            }      
            else
            {
                rte.htmlText = ""; 
                editBtn.enabled = false;
                deleteBtn.enabled = false;
                tagBtn.enabled = false;                                                                                     
            }     
        }

        protected function onEdit(event:Event):void
        {
            if (discussionsTree.selectedItem is Topic)
            {                            
                var topic:Topic = discussionsTree.selectedItem as Topic;
                if (this.editView == null)
                {
                    editView = EditTopicView(PopUpManager.createPopUp(this, EditTopicView, false));
                    editView.onComplete = editTopicDialogComplete;
                    editView.topic = topic;
                }   
                else
                {
                   PopUpManager.addPopUp(editView, this);
                   editView.titleTextInput.text = topic.title;
                   editView.setContent(topic.content);
                   editView.onComplete = editTopicDialogComplete;
                   editView.topic = topic;
                }
            }      
        }

        private function editTopicDialogComplete(topic:Topic):void
        {
            var content:String = topic.content;
            rte.htmlText = content;
            
            var url:String = model.ecmServerConfig.urlPrefix + "/api/forum/post/node/workspace/SpacesStore/" + topic.id;
            url = url + "?alf_ticket=" + model.userInfo.loginTicket + "&alf_method=PUT";
            var obj:Object = new Object();
            obj.container = "discussions";
            obj.content = topic.content;
            obj.site = site;            
            obj.title = topic.title;
            var jsonStr:String = JSON.stringify(obj);                        
            
            var request:URLRequest = new URLRequest(url);
            request.contentType = "application/json";
            request.data = jsonStr;
            request.method = "POST";
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onEditTopicComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorEditTopic);
            loader.load(request);
        }
               
        private function onEditTopicComplete(event:Event):void 
        {
            //trace("URLLoader onEditTopicComplete()");
        }        

        private function onIOErrorEditTopic(e:IOErrorEvent):void 
        {
            trace("URLLoader onIOErrorEditTopic()");
        }

        protected function onDelete(event:Event):void
        {
            if (discussionsTree.selectedItem is Topic)
            {                            
                var topic:Topic = discussionsTree.selectedItem as Topic;
                var items:Array = new Array();
                items.push(topic);
                var deleteEvent:DeleteNodesUIEvent = new DeleteNodesUIEvent(DeleteNodesUIEvent.DELETE_NODES_UI, null, items, this, onDeleteComplete);
                deleteEvent.dispatch();                                                            
            }                  
        }
        
        private function onDeleteComplete():void
        {
            rte.htmlText = "";
            discussionsTree.selectedItem = null;

            updateAll();
        }

        protected function onTag(event:Event):void
        {
            if (discussionsTree.selectedItem is Topic)
            {                            
                var topic:Topic = discussionsTree.selectedItem as Topic;
                var tagEvent:TagsCategoriesUIEvent = new TagsCategoriesUIEvent(TagsCategoriesUIEvent.TAGS_CATEGORIES_UI, null, topic, this, null);
                tagEvent.dispatch();
            }             
        }

        protected function onNewTopic(event:Event):void
        {
            if (this.createView == null)
            {
                createView = CreateTopicView(PopUpManager.createPopUp(this, CreateTopicView, false));
                createView.onComplete = createTopicDialogComplete;
                createView.topic = new Topic();
            }   
            else
            {
               PopUpManager.addPopUp(createView, this);
               createView.onComplete = createTopicDialogComplete;
               createView.topic = new Topic;
            }            
        }

        private function createTopicDialogComplete(topic:Topic):void
        {
            rte.htmlText = "";
            discussionsTree.selectedItem = null;

            var content:String = topic.content;
            
            var url:String = model.ecmServerConfig.urlPrefix + "/api/forum/site/" + site + "/discussions/posts";
            url = url + "?alf_ticket=" + model.userInfo.loginTicket;
            var obj:Object = new Object();
            obj.container = "discussions";
            obj.content = topic.content;
            obj.site = site;            
            obj.title = topic.title;
            var jsonStr:String = JSON.stringify(obj);                        
            
            var request:URLRequest = new URLRequest(url);
            request.contentType = "application/json";
            request.data = jsonStr;
            request.method = "POST";
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onCreateTopicComplete);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorCreateTopic);
            loader.load(request);
        }
        
        private function onCreateTopicComplete(event:Event):void 
        {
            //trace("DiscussionsPodBase onCreateTopicComplete()");
            
            updateAll();            
        }        
        
        private function onIOErrorCreateTopic(e:IOErrorEvent):void 
        {
            trace("DiscussionPodBase onIOErrorCreateTopic()");
        }
    
		protected function onSelectSite(event:IndexChangeEvent):void
		{	
			if (siteList.length > 0)
			{
				var siteInfo:Object = siteList.getItemAt(event.newIndex);
				this.site = siteInfo.shortName;
			}
			rte.htmlText = ""; 			
			updateAll();
		}
		
    }
}