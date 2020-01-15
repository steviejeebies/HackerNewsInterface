class ScrollBar {    //Written by Stephen. Draws a scroll bar, relative to the size of the content on screen.
  float x, y;
  float barWidth, barHeight;
  float sliderWidth, sliderHeight, screenTotalHeightAllContent, screenTotalHeightToBar;
  float sliderYPos;
  int event;
  boolean holdScroll = false;
  boolean moveDown = false;
  boolean moveUp = false;
  float offsetMouseY;

  ScrollBar(float x, float y, float barWidth, float barHeight, float sliderHeight, float screenTotalHeightAllContent, int event) { 
    this.x = x;
    this.y = y;
    this.barWidth = barWidth;
    this.barHeight = barHeight;
    this.sliderWidth = barWidth;
    this.sliderHeight = sliderHeight;
    this.screenTotalHeightAllContent = screenTotalHeightAllContent;    //Stephen: whenever makeStoryWidgets or makeCommentWidgets in main is called, a new screenTotalHeightAllContent value is created, which is passed as a parameter to Scroll bar. This will determine the size of the scrollbar and how much the content should be shifted up and down.
    this.event = event;
    sliderYPos = y;
  }

  int getEvent(float mX, float mY) 
  {
    if (mX > x && mX < x+barWidth && mY > y && mY < y+barHeight)
      return event;
    return 0;
  }

  void move(float mY)       //Stephen: This method is solely for moving the rectangle of the scrollbar and making sure it does not go out of bounds. It then calls changeStoryHeight which will shift the content.
  {
    if (mY-(sliderHeight/2) < y) sliderYPos = y;              
    else if (mY+(sliderHeight/2) > y+barHeight) sliderYPos = y+barHeight-sliderHeight;
    else sliderYPos = mY-(sliderHeight/2);

    changeStoryHeight();
  }

  void changeStoryHeight()    //method for shifting the storys/comment/subcomments up and down on screen
  {
    if (currentScreenType == SCREEN_STORY)
    {
      for (StoryWidget storyMove : storyDisplay)
      {
        storyMove.moveY((this.screenTotalHeightAllContent*(sliderYPos-y)/(barHeight-sliderHeight/2)));    //This value that is passed as a parameter to moveY is the percentage that the slider has moved relative to the full scroll bar, then multipies this by the totalHeightAllContent to find what percentage the each story should be shifted, then passes it as a parameter to each story widget on screen's moveY function.
      }
    }
    else if (currentScreenType == SCREEN_COMMENT)
    {
      for (CommentWidget commentMove : commentDisplay)
      {
        commentMove.moveY((this.screenTotalHeightAllContent*(sliderYPos-y)/(barHeight-sliderHeight/2)));
      }
    }
    else if (currentScreenType == SCREEN_SUBCOMMENT)
    {
      for (CommentWidget subCommentMove : subCommentDisplay)
      {
        subCommentMove.moveY((this.screenTotalHeightAllContent*(sliderYPos-y)/(barHeight-sliderHeight/2)));
      }
    }
  }

  void draw() 
  {    
    fill(lerpColor(backgroundColor, widgetBackgroundColor, 0.5)); 
    noStroke();
    rect(x, y, barWidth, barHeight);

    if(!(sliderHeight >= SCROLL_BAR_HEIGHT))
    {
      fill(widgetItemColor); 
      stroke(plainText); 
      strokeWeight(1);
      rect(x, sliderYPos, SCROLL_BAR_WIDTH, sliderHeight);
    }
  }

  void setWheel(float wheelIncrement)
  {
    if(sliderYPos >= y && sliderYPos + sliderHeight <= y + barHeight) sliderYPos+= wheelIncrement * 10;
    if(sliderYPos + sliderHeight > y + barHeight) sliderYPos = y+barHeight-sliderHeight;
    if(sliderYPos < y) sliderYPos = y;
     changeStoryHeight();            //similar to the move function above, when the wheel has shfited the scroll bar, the stories must also be shifted.
  }

  void mousePressedRect()
  {
    if (mouseOver())
    {
      holdScroll = true;
      offsetMouseY = mouseY-y;
    }
  }

  boolean mouseOver()
  {
    return mouseX>x&&
      mouseX<x+barWidth&&
      mouseY>y&&
      mouseY<y+barHeight;
  }
  
  void setRatioAndHeight()
  {
    this.screenTotalHeightAllContent = totalHeightAllContent; //gets totalHeightAllContent and ratioSliderToBar from main that has been changed when last page page is clicked
    this.sliderHeight = ratioSliderToBar*SCROLL_BAR_HEIGHT;
  }
}
