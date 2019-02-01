
int aNum = 20000;
PVector[] agents = new PVector[aNum];
float nS = 0.002;//noise scale
float maxRot = 4;//width of rotation change with noise.
float delta = 2;//distance which particles move in 1frame.

void setup(){
  size(1024,1024);
  background(255);
  stroke(0, 20);
  smooth();
  strokeWeight(2);
  initPos();
}

void draw(){
  updatePos();
}

void initPos(){
  for(int i=0; i<aNum; i++){
    agents[i] = new PVector(random(-50,width+50), random(-50,height+50));
  }
}

void updatePos(){
  for(int i=0; i<aNum; i++){
    float n = cellularNoise(agents[i].copy().mult(nS));
    float a = n * TWO_PI * maxRot;
    PVector pre = agents[i];
    agents[i].x += cos(a)*delta;
    agents[i].y += sin(a)*delta;
    line(pre.x,pre.y,agents[i].x,agents[i].y);
  }
}

void keyPressed(){
  println(key);
  if(key == 's'){
    saveFrame(year()+"_"+month()+"_"+day()+"_"+hour()+"_"+minute()+"_"+second()+".png");
  }
}

/////////////////////////////////
// Noise functions and some functions which is needed for noise functions.
//
// These are 2D noise. if you need 3DNoise functions, you need to fix functions.
// Argument is Pvector variable.
// Return is float (0~1)
//
// float perlineNoise (PVector vec) {}
// float valueNoise (PVector vec) {}
// float cellularNoise (PVector vec) {}
// float fbm (PVector vec) {}

PVector floor(PVector vec) {
  PVector copy = vec.copy();
  copy.x = floor(copy.x);
  copy.y = floor(copy.y);
  copy.z = floor(copy.z);
  return copy;
}

float frac(float f) {
  return f - floor(f);
}

PVector frac(PVector vec) {
  PVector copy = vec.copy();
  copy.x = frac(copy.x);
  copy.y = frac(copy.y);
  copy.z = frac(copy.z);
  return copy;
}

PVector sin(PVector vec) {
  PVector copy = vec.copy();
  copy.x = sin(copy.x);
  copy.y = sin(copy.y);
  copy.z = sin(copy.z);
  return copy;
}

float rand(float n) {
  return frac(sin(n) * 43758.5453123);
}

float rand(PVector vec) {
  PVector copy = vec.copy();
  return rand(copy.dot(new PVector(12.9898, 78.2335, 45.6345)));
}

PVector rand2D(PVector st) {
  PVector copy = st.copy();
  copy = new PVector( copy.dot(new PVector(127.1, 311.7)), 
    copy.dot(new PVector(269.5, 183.3)) );
  return frac(sin(copy).mult(43758.5453123)).mult(2.0).add(new PVector(-1, -1, 0));
}

float saturate(float x) {
  if (x > 1) {
    return 1;
  } else if (x < 0) {
    return 0;
  } else {
    return x;
  }
}

float smoothstep(float edge0, float edge1, float x) {
  float t;  /* Or genDType t; */
  t = saturate((x - edge0) / (edge1 - edge0));
  return t * t * (3.0 - 2.0 * t);
}

PVector smoothstep(PVector edge0, PVector edge1, PVector vec) {
  PVector copy = vec.copy();
  copy.x = smoothstep(edge0.x, edge1.x, vec.x);
  copy.y = smoothstep(edge0.y, edge1.y, vec.y);
  copy.z = smoothstep(edge0.z, edge1.z, vec.z);
  return copy;
}

float valueNoise(PVector uv) {
  PVector copy = uv.copy();
  PVector i = floor(copy);
  PVector f = frac(copy);

  PVector zero = new PVector(0, 0, 0);
  PVector one  = new PVector(1, 1, 1);

  PVector sm = smoothstep(zero, one, f);

  //o = origin
  float rand_o  = rand(i);
  float rand_x  = rand(i.copy().add(new PVector(1.0, 0.0)));
  float rand_y  = rand(i.copy().add(new PVector(0.0, 1.0)));
  float rand_xy = rand(i.copy().add(new PVector(1.0, 1.0)));

  float value_x  = lerp(rand_o, rand_x, sm.x);
  float value_y1 = lerp(0, rand_y - rand_o, sm.y);
  float value_y2 = lerp(0, rand_xy - rand_x, sm.y);
  float value_y  = lerp(value_y1, value_y2, sm.x);//1と2をブレンド
  return value_x + value_y;
}

float perlineNoise(PVector pos) {
  PVector copy = pos.copy();
  PVector i_o = floor(copy);
  PVector f = frac(copy);

  PVector zero = new PVector(0, 0, 0);
  PVector one  = new PVector(1, 1, 1);

  PVector sm = smoothstep(zero, one, f);

  PVector i_x  = i_o.copy().add(new PVector(1, 0));
  PVector i_y  = i_o.copy().add(new PVector(0, 1));
  PVector i_xy = i_o.copy().add(new PVector(1, 1));
  PVector rand_o  = rand2D(i_o);
  PVector rand_x  = rand2D(i_x);
  PVector rand_y  = rand2D(i_y);
  PVector rand_xy = rand2D(i_xy);

  PVector toPos_o  = copy.copy().sub(i_o);
  PVector toPos_x  = copy.copy().sub(i_x);
  PVector toPos_y  = copy.copy().sub(i_y);
  PVector toPos_xy = copy.copy().sub(i_xy);

  float dot_o  = rand_o.dot(toPos_o )*0.5+0.5;
  float dot_x  = rand_x.dot(toPos_x )*0.5+0.5;
  float dot_y  = rand_y.dot(toPos_y )*0.5+0.5;
  float dot_xy = rand_xy.dot(toPos_xy)*0.5+0.5;

  float value1 = lerp(dot_o, dot_x, sm.x);
  float value2 = lerp(dot_y, dot_xy, sm.x);
  float value3 = lerp(0, value2 - value1, sm.y);
  return value1 + value3;
}

float cellularNoise(PVector pos) {
  PVector copy = pos.copy();
  PVector i_o = floor(copy);
  
  float minDist = 10000;
  for(int i = -1; i <= 1; i++){
    for(int j = -1; j <= 1; j++){
      PVector neighbor = i_o.copy().add(new PVector( i, j, 0));
      PVector random = neighbor.copy().add( rand2D(neighbor).mult(0.5).add(new PVector(0.5,0.5,0)) );
      float dist = (copy.copy().sub(random)).mag();
      if(dist < minDist) minDist = dist;
    }
  }
  return minDist / 1.41421356;
}

float fbm(PVector uv){
    float gain = 0.5;
    float freqIncrease = 2.0;
    float octaves = 3;
    
    //default value
    float amp = 0.5;
    float fre = 1.0;
    
    float ret = 0.0;//return
    float maxValue = 0;
    
    for(int i = 0; i < octaves; i++){
        
        ret += perlineNoise(uv.copy().mult(fre)) * amp;
        fre *= freqIncrease;
        maxValue += amp;
        amp *= gain;
    }
    return ret/maxValue;
}
