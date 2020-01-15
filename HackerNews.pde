import java.util.ArrayList; //<>//
import java.util.Collections;
import java.util.Comparator;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Arrays;
import java.util.Random;

//ARRAYLISTS
ArrayList<StoryData> storyList; 
ArrayList<StoryData> queryStoryBackup; 
ArrayList<StoryData> queryCommentBackup;
ArrayList<StoryData> currentQueryList;  //used for stories, comments and subcomments. As we only need to "remember" full stories when going through the page, we have a "queryStoryList" as backup.

ArrayList<StoryWidget> storyDisplay;
ArrayList<CommentWidget> commentDisplay;
ArrayList<CommentWidget> subCommentDisplay;
ArrayList<Widget> widgetList;

//SCREENS
static Screen storyScreen;
static Screen commentScreen;
static Screen subCommentScreen;

//WIDGETS
Banner banner;
Widget nextPage;
Widget lastPage;
Footer footer;
SortBy sortBy;
Theme theme;
Widget home;
Widget star;

//COLORS
static color headerColor;                //colors are all in main so that we could make a method that switches theme colors for whole program (like a dark mode);
static color widgetBackgroundColor;
static color widgetItemColor;
static color plainText;                  //used for "Hacker News", text of the title of articles, and comments
static color backgroundColor;

//FONTS
static PFont fontTitle;
static PFont fontWidget;
static PFont fontQuery;

//IMAGES
static PImage iconSearch;
static PImage iconHome;
static PImage iconSortBy;
static PImage iconTheme;
static PImage iconRightArrow;
static PImage iconLeftArrow;
static PImage iconStar;
static PImage iconUpvote;

//VARIOUS VARIABLES
static int currentStoryPage = 1;
static int currentCommentPage = 1;
static int resultSize;
static String queryLabelOnScreen;
static String userSearched;
static Long dateSearchedEpoch;
static String dateSearchedString;
static boolean currentlyLoading;

float totalHeightAllContent;
float ratioSliderToBar;
int currentEvent;
int currentQuery;
static float scrolling;

static int currentScreenType;

static StoryWidget clickedOnStory = null;
static CommentWidget commentClicked = null;

void setup() {
  size(1000,900);
  currentQueryList = new ArrayList<StoryData>();
  storyList = new ArrayList<StoryData>();
  storyDisplay = new ArrayList<StoryWidget>();
  commentDisplay = new ArrayList<CommentWidget>();
  subCommentDisplay = new ArrayList<CommentWidget>(); 

  fontTitle = loadFont("CenturyGothic-Bold-75.vlw");
  fontWidget = loadFont("ArialMT-22.vlw");
  fontQuery = loadFont("ArialMT-35.vlw");

  iconSearch = loadImage("searchIcon.png");
  iconHome = loadImage("homeIcon.png");
  iconSortBy = loadImage("sortByIcon.png");
  iconTheme = loadImage("themeIcon.png");
  iconRightArrow = loadImage("rightArrow.png");
  iconLeftArrow = loadImage("leftArrow.png");
  iconStar = loadImage("starIcon.png");
  iconUpvote = loadImage("upvoteIcon.png");

  switchTheme(BLUE_LIGHT_THEME);

  widgetList = new ArrayList();
  banner = new Banner(SCREENX-400, WIDGET_HEIGHT, 350, WIDGET_HEIGHT, iconSearch, SCREEN_STORY, EVENT_SEARCH);
  widgetList.add(banner);
  home = new Widget(0, WIDGET_HEIGHT*3, WIDGET_HEIGHT, WIDGET_HEIGHT, "", iconHome, EVENT_HOME);
  widgetList.add(home);
  sortBy = new SortBy(WIDGET_HEIGHT, WIDGET_HEIGHT*3, WIDGET_WIDTH, WIDGET_HEIGHT, "Sort By", EVENT_SORTBY);
  widgetList.add(sortBy);  
  theme = new Theme(SCREENX-WIDGET_WIDTH, WIDGET_HEIGHT*3, WIDGET_WIDTH, WIDGET_HEIGHT, "Theme", EVENT_THEME);
  widgetList.add(theme);               
  footer = new Footer();
  widgetList.add(footer);



  currentStoryPage = 1;
  currentQuery = SORT_EVENT_LATEST;
  changeQuery(currentQuery, null);
  makeStoryWidgets();
  storyScreen = new Screen(totalHeightAllContent, ratioSliderToBar, SCREEN_STORY);
  commentScreen = new Screen(totalHeightAllContent, ratioSliderToBar, SCREEN_COMMENT);
  subCommentScreen = new Screen(totalHeightAllContent, ratioSliderToBar, SCREEN_SUBCOMMENT);
  currentScreenType = SCREEN_STORY;
  storyScreen.scrollBar.setRatioAndHeight();
  thread("loadData");    //Oisin: gets Load data at the same time as draw is being called, meaning that we can have a loading screen
}

void draw() { 


  if (currentScreenType == SCREEN_STORY) storyScreen.draw();
  if (currentScreenType == SCREEN_COMMENT) commentScreen.draw();
  if (currentScreenType == SCREEN_SUBCOMMENT) subCommentScreen.draw();
}

void loadData() {//By Oisin - Loads data from JSON and initialises arrays.
  currentlyLoading = true;
  try {
    BufferedReader br = createReader("hackerMedium.json"); 
    String line = "";
    boolean endOfFile = false;
    JSONObject singleParsedJSON;
    StoryData singleJSONObjectAsStory;
    while (!endOfFile) {
      line = br.readLine();  
      singleParsedJSON = parseJSONObject(line);
      if (line != null && !singleParsedJSON.isNull("id") && !singleParsedJSON.isNull("by")) {        
        singleJSONObjectAsStory = new StoryData(singleParsedJSON);
        storyList.add(singleJSONObjectAsStory);
        if (singleJSONObjectAsStory.getType().equals("story") && singleJSONObjectAsStory.getDescendants()>=0) {
          currentQueryList.add(singleJSONObjectAsStory);
        }
      }
    }
  }
  catch(Exception e) {
     resultSize = currentQueryList.size();
     changeQuery(EVENT_SEARCH, "");
     currentlyLoading = false;
  }
}

//Adam: convert epoc time into DD/MM/YYYY format
String format(long mnSeconds) {
  SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy, HH:mm:ss");
  return sdf.format(new Date(mnSeconds*1000));
}


//Adam: getTime method used for searching a specific date. Converts normal time to epoc time
long getTime(String searchQuery) {
  {
    long epoch;
    Date date=new Date();
    SimpleDateFormat df = new SimpleDateFormat("dd-MM-yyyy");
    try
    { 
      date = df.parse(searchQuery);
    }
    catch(Exception e) {
    }

    epoch = date.getTime()/1000;
    return epoch;
  }
}
//Adam: gets the current time to display on the screen
String getCurrentTime() {
  SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");  
  Date date = new Date();  
  return(formatter.format(date));
}

ArrayList<StoryData> getImmediateDescendants(StoryData aStory)    //Written by adam, gets the immediate descendants of StoryData and returns it as an arraylist of story data
{
  ArrayList descendants = new ArrayList();
  int[] des = aStory.kids;
  if (des != null)
  {
    for (int i=0; i<des.length-1; i++) 
    {
      int ID = des[i];
      if (ID<storyList.size())
      {
        for (int j=0; j<storyList.size()-1; j++)
        {
          StoryData comment=storyList.get(j);
          if (ID==comment.id)
          {
            descendants.add(comment);
          }
        }
      }
    }
  }

  return descendants;
}

ArrayList<StoryData> getCommentDescendants(ArrayList<StoryData> parent, int recursionCounter) //Stephen: Gets the subcomments, subcomments of subcomments, and so on, so that an entire list is created in the order of <parent><comment1><comment2><comment2subcomment1><comment3> etc. Also sets an indent value (counted by the number of recursions into this method) and adds it the the StoryData for a given comment,to be used later by makeCommentWidget();
{
  ArrayList<StoryData> allDescendants = new ArrayList<StoryData>();

  if (parent.size()>0)
  {
    ArrayList<StoryData> immediateDescendants = getImmediateDescendants(parent.get(parent.size()-1));  // gets last StoryData from the arraylist passed as a parameter

    for (int i = 0; i < immediateDescendants.size(); i++)
    {
      StoryData currentComment = immediateDescendants.get(i);
      currentComment.setSubCommentIndentValue(recursionCounter);        //sets a value of the storyData of a given comment by how much it should be indented relative to the comment displaying above it, will be used by makeCommentWidgets later.
      allDescendants.add(currentComment);
      allDescendants.addAll(getCommentDescendants(allDescendants, recursionCounter+1));  //recursion, adds all descendants found by recursion to the allDescendants ArrayList, increments indent by how far into recursion it currently is
    }
    return allDescendants;
  }
  return null;
}

void makeStoryWidgets() //based on Oisins code
{   
  int eventForStory = 1;
  if (storyDisplay!=null) storyDisplay.clear();

  totalHeightAllContent = STORY_PADDING; 
  if (queryStoryBackup.size() > 0)
  {
    int currentLoopIteration = 0;  //Stephen: Need this as we can't use the variable i to compare to storyDisplay.size(), as I will be much greater in later pages of the query.
    for (int i = (currentStoryPage*STORY_PER_PAGE)-STORY_PER_PAGE; (i < currentStoryPage*STORY_PER_PAGE) && i<queryStoryBackup.size(); i++)
    {
      StoryWidget tempObj = new StoryWidget(SCREENX*0.05, totalHeightAllContent + STORY_DEFAULT_Y_POS, STORY_WIDTH, STORY_HEIGHT, eventForStory, queryStoryBackup.get(i)); 
      storyDisplay.add(tempObj);
      if (currentLoopIteration < storyDisplay.size()) totalHeightAllContent += tempObj.height + 30 + STORY_PADDING;  //if stories have different height, this line makes sure that they total height of the story is added to totalHeightOfContent.
      eventForStory++;
      currentLoopIteration++;
    }
  }
  ratioSliderToBar = VISIBLE_PIXELS_AT_GIVEN_MOMENT/totalHeightAllContent;

  if (storyScreen != null) storyScreen.scrollBar.setRatioAndHeight(); //Stephen: sets the scrollBar variables on screen to the correct values so that it represents the current storyDisplay().
}

//Adam. Method to get the poll options for Poll data type
ArrayList<StoryData> getPollOptions(StoryData poll) {
  ArrayList<StoryData> pollOpts= new ArrayList<StoryData>();
  int[] pollOptions = poll.parts;
  
  for (StoryData pollOption : storyList) {
    if (pollOption.type.equals("pollopt") && pollOption.parent == poll.id) pollOpts.add(pollOption);
  }

  return pollOpts;
}


void makeCommentWidgets() {    //Based on adam's addComment() method from earlier version, and stephen's makeStoryWidgets() from this version

  int eventForComment = 1;

  if (currentScreenType == SCREEN_STORY && commentDisplay != null) commentDisplay.clear();              //clears the commentDisplay so that old comments are removed
  else if (currentScreenType == SCREEN_COMMENT && commentDisplay != null) commentDisplay.clear(); //clears the subCommentDisplay so old comments are removed
  if (subCommentDisplay != null) subCommentDisplay.clear();

  if (currentScreenType == SCREEN_COMMENT) 
  {
    clickedOnStory.setY(STORY_DEFAULT_Y_POS + STORY_PADDING);               //Sets the ypos of the current clicked on story so it appears at the top of the comment screen
    totalHeightAllContent = clickedOnStory.height + STORY_PADDING*3;        //On the comment page, we need to make space for the clicked-on story, so that we can display the Story at the top of the page.
  } else if (currentScreenType == SCREEN_SUBCOMMENT) totalHeightAllContent = STORY_PADDING;                          //On the subcomment page, we do not need to make space for the story, we can just show all the comments.

  if (currentScreenType == SCREEN_COMMENT && queryCommentBackup != null)      //for creating the widgets on Comment page
  {
    if (queryCommentBackup.size() > 0)        //if there are comments to draw
    {
      int currentLoopIteration = 0;  //Stephen: Need this as we can't use the variable i to compare to storyDisplay.size(), as I will be much greater in later pages of the query.
      for (int i = (currentCommentPage*STORY_PER_PAGE)-STORY_PER_PAGE; i < currentCommentPage*STORY_PER_PAGE && i<queryCommentBackup.size(); i++)
      {
        CommentWidget comment = new CommentWidget(COMMENT_INDENT, totalHeightAllContent + STORY_DEFAULT_Y_POS, COMMENT_WIDTH, COMMENT_HEIGHT, null, eventForComment, queryCommentBackup.get(i));
        commentDisplay.add(comment);
        if (currentLoopIteration < commentDisplay.size()) totalHeightAllContent += comment.height + 1;  //increment totalHeightAllContent by the height of the last comment widget created
        eventForComment++;                                          //increment event for comment so every comment has a unique event.
      }
      ratioSliderToBar = VISIBLE_PIXELS_AT_GIVEN_MOMENT/totalHeightAllContent;
      commentScreen.scrollBar.setRatioAndHeight();                  //resets the scroll bar on comment screen so it is the right proportions for the current batch of comments in queryCommentBackup
    }
  } else if (currentScreenType == SCREEN_SUBCOMMENT)    //for creating the widgets on subcomment page
  {
    if (currentQueryList.size() > 1)    //greater than 1, as the currentQueryList will at least contain the clicked on comment, due to how we create the subComment arraylist.
    {
      for (int i = 0; i<currentQueryList.size(); i++)
      {
        CommentWidget comment = new CommentWidget(COMMENT_INDENT, totalHeightAllContent + STORY_DEFAULT_Y_POS, COMMENT_WIDTH, COMMENT_HEIGHT, null, 0, currentQueryList.get(i));  //event is 0 because the user will not be allowed to click on subcomments
        subCommentDisplay.add(comment);
        totalHeightAllContent += subCommentDisplay.get(i).height + 1;
      }
      ratioSliderToBar = VISIBLE_PIXELS_AT_GIVEN_MOMENT/totalHeightAllContent;
      subCommentScreen.scrollBar.setRatioAndHeight();
    }
  }
}

void changeQuery(int currentQuery, String searchQuery)  //Main sorting written by Stephen, as well as searching for user. Adam wrote section on finding posts by date.
{ 
  if (currentScreenType == SCREEN_COMMENT && commentDisplay != null)
  {  
    commentDisplay.clear();                //bug fix, comments are now displaying correctly when sorted
    currentCommentPage = 1;                //resets the comment page to 1 if the user ever sorts comments
  }

  if (currentScreenType == SCREEN_STORY && storyScreen != null) currentQueryList = (ArrayList<StoryData>) queryStoryBackup.clone();
  else if (currentScreenType == SCREEN_COMMENT && commentScreen != null) currentQueryList = queryCommentBackup;

  if (currentQuery == SORT_EVENT_MOST_LIKED)
  {
    queryLabelOnScreen = (userSearched==null && dateSearchedString == null) ? "Highest Rated" : ((dateSearchedString==null) ? "User: " + userSearched + ", Highest Rated" : "Date: " + dateSearchedString + ", Highest Rated");
    Collections.sort(currentQueryList, new Comparator<StoryData>() {
      public int compare(StoryData storyA, StoryData storyB) {
        return storyB.score - storyA.score;
      }
    }
    );
    if (currentScreenType == SCREEN_STORY) queryStoryBackup = (ArrayList<StoryData>) currentQueryList.clone();     //if the user is sorting stories
    queryCommentBackup = currentQueryList;    //if the user is sorting comments
  }
  if (currentQuery == SORT_EVENT_LEAST_LIKED)
  {
    queryLabelOnScreen = (userSearched==null && dateSearchedString == null)  ? "Lowest Rated" : ((dateSearchedString==null) ? "User: " + userSearched + ", Lowest Rated" : "Date: " + dateSearchedString + ", Lowest Rated");
    Collections.sort(currentQueryList, new Comparator<StoryData>()
    {
      public int compare(StoryData storyA, StoryData storyB) 
      {
        return storyA.score - storyB.score;
      }
    }
    );
    if (currentScreenType == SCREEN_STORY) queryStoryBackup = (ArrayList<StoryData>) currentQueryList.clone();     //if the user is sorting stories
    queryCommentBackup = currentQueryList;    //if the user is sorting comments
  }
  if (currentQuery == SORT_EVENT_MOST_COMMENTED)
  {
    queryLabelOnScreen = (userSearched==null && dateSearchedString == null) ? "Most Discussed" : ((dateSearchedString==null) ? "User: " + userSearched + ", Most Discussed" : "Date: " + dateSearchedString + ", Most Discussed");

    Collections.sort(currentQueryList, new Comparator<StoryData>() {
      public int compare(StoryData storyA, StoryData storyB) {
        return storyB.descendants - storyA.descendants;
      }
    }
    );
    if (currentScreenType == SCREEN_STORY) queryStoryBackup = (ArrayList<StoryData>) currentQueryList.clone();     //if the user is sorting stories
    queryCommentBackup = currentQueryList;    //if the user is sorting comments
  }
  if (currentQuery == SORT_EVENT_LEAST_COMMENTED)
  {
    queryLabelOnScreen = (userSearched==null && dateSearchedString == null) ? "Latest Stories" :((dateSearchedString==null) ? "User: " + userSearched + ", Least Discussed" : "Date: " + dateSearchedString + ", Least Discussed");
    Collections.sort(currentQueryList, new Comparator<StoryData>() 
    {
      public int compare(StoryData storyA, StoryData storyB) 
      {
        return storyA.descendants - storyB.descendants;
      }
    }
    );
    if (currentScreenType == SCREEN_STORY) queryStoryBackup = (ArrayList<StoryData>) currentQueryList.clone();     //if the user is sorting stories
    queryCommentBackup = currentQueryList;    //if the user is sorting comments
  }
  if (currentQuery == SORT_EVENT_LATEST)
  {
    queryLabelOnScreen = (userSearched==null && dateSearchedString == null) ? "Latest Stories" :((dateSearchedString==null) ? "User: " + userSearched + ", Latest Stories" : "Date: " + dateSearchedString + ", Latest Stories");
    Collections.sort(currentQueryList, new Comparator<StoryData>() 
    {
      public int compare(StoryData storyA, StoryData storyB) 
      {
        return storyB.time - storyA.time;
      }
    }
    );
    if (currentScreenType == SCREEN_STORY) queryStoryBackup = (ArrayList<StoryData>) currentQueryList.clone();     //if the user is sorting stories
    queryCommentBackup = currentQueryList;    //if the user is sorting comments
  }
  if (currentQuery == SORT_EVENT_OLDEST)
  {
    queryLabelOnScreen = (userSearched==null && dateSearchedString == null) ? "Oldest Stories" : ((dateSearchedString==null) ? "User: " + userSearched + ", Oldest Stories" : "Date: " + dateSearchedString + ", Oldest Stories");
    Collections.sort(currentQueryList, new Comparator<StoryData>() 
    {
      public int compare(StoryData storyA, StoryData storyB) 
      {
        return storyA.time - storyB.time;
      }
    }
    );
    if (currentScreenType == SCREEN_STORY) queryStoryBackup = (ArrayList<StoryData>) currentQueryList.clone();     //if the user is sorting stories
    queryCommentBackup = currentQueryList;    //if the user is sorting comments
  }
  if (currentQuery == EVENT_SEARCH)
  {
    currentQueryList.clear();
    queryStoryBackup.clear();    //searching will immediately return to story screen, so we only need to clear queryStoryBackup.

    if (searchQuery.length()>5)
    {
      if (searchQuery.substring(0, 5).equalsIgnoreCase("user:"))    //finds username entered in search bar
      {
        userSearched = searchQuery.substring(5).replaceAll(" ", "");  //removes any spaces from String, and the first five chars (i.e. "user:") to get the username
        dateSearchedEpoch = null;
        dateSearchedString = null;
      } else if (searchQuery.substring(0, 5).equalsIgnoreCase("date:"))  //finds date entered in search bar
      {
        dateSearchedEpoch = getTime(searchQuery.substring(5).replaceAll(" ", ""));  //removes any spaces from date string
        dateSearchedString = searchQuery.substring(5).replaceAll(" ", "");           //makes date as a string
        userSearched = null;
      } else
      {
        dateSearchedEpoch = null;      //clears date searched and user searched variables if user has not typed either "user:" or "date:"
        dateSearchedString = null;
        userSearched = null;
      }
    } else                      //last else block from just above repeated, just in case the search query is less than 5 chars and it didn't enter the above if statement.
    {
      dateSearchedEpoch = null;      //clears date searched and user searched variables if user has not typed either "user:" or "date:"
      dateSearchedString = null;
      userSearched = null;
    }

    for (StoryData currentStory : storyList) {
      if (currentStory.title != null && !currentStory.getType().equals("pollopt"))
      { 
        if (userSearched != null && (currentStory.getBy().equalsIgnoreCase(userSearched)) && currentStory.getType().equals("story"))
        {
          if (currentStory.getDescendants() >= 0)    //bug fix, it was getting stories with -1 descendants, which I think are actually user reports
          { 
            currentQueryList.add(currentStory);
          }
        } else if (dateSearchedEpoch != null && currentStory.time>dateSearchedEpoch && currentStory.time<dateSearchedEpoch+86400 && currentStory.getType().equals("story"))
        {
          if (currentStory.getDescendants() >= 0)    //bug fix, it was getting stories with -1 descendants, which I think are actually user reports
          currentQueryList.add(currentStory);
        } else if (currentStory.title.toLowerCase().contains(searchQuery.toLowerCase())) 
        {
          if (currentStory.getDescendants() >= 0)    //bug fix, it was getting stories with -1 descendants, which I think are actually user reports
          {     
            currentQueryList.add(currentStory);
            userSearched = null;
          }
        }
      }
      resultSize = currentQueryList.size();
    }

    if (!searchQuery.equals("")) 
    {

      Collections.sort(currentQueryList, new Comparator<StoryData>() {
        public int compare(StoryData storyA, StoryData storyB) {
          return storyB.score - storyA.score;
        }
      }
      );

      queryLabelOnScreen = (userSearched==null && dateSearchedString == null) ? "Results for \"" + searchQuery + "\"" : ((dateSearchedString==null) ? "User: " + userSearched + ", Highest Rated" : "Date: " + dateSearchedString + ", Highest Rated");
    } else
    {
      Collections.sort(currentQueryList, new Comparator<StoryData>() {
        public int compare(StoryData storyA, StoryData storyB) {
          return storyB.time - storyA.time;
        }
      }
      );
      queryLabelOnScreen = "Latest Stories";
    }
    queryStoryBackup = (ArrayList<StoryData>) currentQueryList.clone();
  }



  //finally make story/comment widgets, regardless of type or sortby/search query.
  if (currentScreenType == SCREEN_COMMENT && currentQuery != EVENT_SEARCH)
  {
    currentCommentPage = 1;
    makeCommentWidgets();
    commentScreen = new Screen(totalHeightAllContent, ratioSliderToBar, SCREEN_COMMENT);
  } else
  {
    currentScreenType = SCREEN_STORY;
    currentStoryPage = 1;
    makeStoryWidgets();
    storyScreen = new Screen(totalHeightAllContent, ratioSliderToBar, SCREEN_STORY);
  }
}


void switchTheme(int themeNum)
{
  switch(themeNum) 
  {
  case BLUE_LIGHT_THEME:
    headerColor = BLUE_LIGHT_BANNER;
    widgetBackgroundColor = BLUE_LIGHT_WIDGET_BG;
    widgetItemColor = BLUE_LIGHT_WIDGET_ITEM;
    plainText = LIGHT_MODE_PLAIN_TEXT;
    backgroundColor = LIGHT_BACKGROUND;
    break;
  case RED_LIGHT_THEME:
    headerColor = RED_LIGHT_BANNER;
    widgetBackgroundColor = RED_LIGHT_WIDGET_BG;
    widgetItemColor = RED_LIGHT_WIDGET_ITEM;
    plainText = LIGHT_MODE_PLAIN_TEXT;
    backgroundColor = LIGHT_BACKGROUND;
    break;
  case BLUE_DARK_THEME:
    headerColor = BLUE_DARK_BANNER;
    widgetBackgroundColor = BLUE_DARK_WIDGET_BG;
    widgetItemColor = BLUE_DARK_WIDGET_ITEM;
    plainText = DARK_MODE_PLAIN_TEXT;
    backgroundColor = DARK_BACKGROUND;
    break;
  case RED_DARK_THEME:
    headerColor = RED_DARK_BANNER;
    widgetBackgroundColor = RED_DARK_WIDGET_BG;
    widgetItemColor = RED_DARK_WIDGET_ITEM;
    plainText = DARK_MODE_PLAIN_TEXT;
    backgroundColor = DARK_BACKGROUND;
    break;
  case ORANGE_DARK_THEME:
    headerColor = ORANGE_DARK_BANNER;
    widgetBackgroundColor = ORANGE_DARK_WIDGET_BG;
    widgetItemColor = ORANGE_DARK_WIDGET_ITEM;
    plainText = DARK_MODE_PLAIN_TEXT;
    backgroundColor = DARK_BACKGROUND;
  }
}

void keyPressed()
{
  if(currentlyLoading) return;
  if (currentEvent == EVENT_SEARCH)
  {
    if (key == RETURN || key == ENTER)
    {
      currentScreenType = SCREEN_STORY;
      changeQuery(EVENT_SEARCH, banner.getSearchQuery());
    } else banner.typing(key);
  }
}

void mouseDragged()
{
  if(currentlyLoading) return;
  if (currentEvent == EVENT_SCROLL_BAR) 
  {    
    if (currentScreenType == SCREEN_STORY) storyScreen.moveScrollBar(mouseY);
    else if (currentScreenType == SCREEN_COMMENT) commentScreen.moveScrollBar(mouseY);
    else if (currentScreenType == SCREEN_SUBCOMMENT) subCommentScreen.moveScrollBar(mouseY);
  }
}


void mousePressed()
{
  if(currentlyLoading) return; 
  if (currentScreenType == SCREEN_STORY) storyScreen.mousePressed();
  else if (currentScreenType == SCREEN_COMMENT) commentScreen.mousePressed();
  else if (currentScreenType == SCREEN_SUBCOMMENT) subCommentScreen.mousePressed();
}

void mouseWheel(MouseEvent event)
{
  if(currentlyLoading) return;
  if (currentScreenType == SCREEN_STORY) storyScreen.scrollBar.setWheel(event.getCount());
  else if (currentScreenType == SCREEN_COMMENT) commentScreen.scrollBar.setWheel(event.getCount());
  else if (currentScreenType == SCREEN_SUBCOMMENT) subCommentScreen.scrollBar.setWheel(event.getCount());
}

void mouseMoved()
{
  if(currentlyLoading) return;
  if(currentScreenType == SCREEN_STORY)
  {
    for(int i = 0; i<storyDisplay.size(); i++)
    {
      storyDisplay.get(i).underLineURL(mouseX, mouseY);
    }
  }
}
