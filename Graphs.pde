//Graph class by Adam. At the moment it just works for the top Score, however will work on allowing 
 //it to work for whichever value passed as theType in constructor



class Graphs{
  int numberOfBars;
  ArrayList<StoryData> list = new ArrayList<StoryData>();
  String theType;
  String text;
  int barWidth;
  int barHeight;
  int x;
  int y;
  int gap;
  color BarColor;
  Random random = new Random();
  
  Graphs(int number, ArrayList list, String theType, StoryData story){
    this.numberOfBars = number;
    this.list = list;
    this.theType = theType;
    text=story.text;
    barWidth = (WINDOW-3*MARGIN) / number;
    x=MARGIN/2;
    y=20;
    BarColor = color(360, 60, 150);
    gap=(int)(SCREENX-barWidth*number)/number +40;
  }
  
  void draw(){
    background(255,255,255);
    fill(0);
    text(text, SCREENX/2, 200);
    stroke(50);
    fill(BarColor);
      color(100);
      text("score", 400, 200);
    for(int i =0;i<numberOfBars;i++){
     StoryData story = list.get(i); 
   
     String user = story.text;                          //get the userName
     //userList.userComments(user, list);                    //create arrayList in the Lists class of specified user
     int score = story.score/2;                          //score of the poll option
   
     barHeight = score;
     rect(x,WINDOW-y,barWidth,-barHeight);
       textSize(24);
     text(score, x+30,WINDOW-y-10-barHeight);
      textSize(15);
     text(user, x+20,WINDOW-y+20);
     x=x+gap;
    }
    
    
  }

  
}
