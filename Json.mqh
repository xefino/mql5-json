#property copyright "Copyright © 2006-2017"
#property version "1.00"
#property strict

// JSON type enum used to describe the type on various fields
enum NodeType {
   Undefined   = 0x0,
   Null        = 0x1,
   Bool        = 0x2,
   Integer     = 0x3,
   Double      = 0x4,
   String      = 0x5,
   Array       = 0x6,
   Object      = 0x7
};

const string num = "0123456789+-.eE";

class JSONNode {
private:

   JSONNode    m_e[];      // Child nodes to this node
   string      m_key;
   string      m_lkey;
   JSONNode*   m_parent;   // The parent node for this node
   NodeType    m_type;     // The datatype of this node
   bool        m_bv;       // Boolean value contained in this node
   long        m_iv;       // Integer value contained in this node
   double      m_dv;       // Double value contained in this node
   int         m_prec;     // Floating-point precision for the value contained in this node
   string      m_sv;       // String value contained in this node
   static int  code_page;  // Code page to use for representing data on the node
   
   virtual void Clear(NodeType jt = Undefined, bool savekey = false);
   virtual bool Copy(const JSONNode &node);
   virtual void CopyData(const JSONNode &node);
   virtual void CopyArray(const JSONNode &node);
   virtual void FromString(const NodeType type, const string raw);
   virtual string GetString(const char& js[], const int i, const int slen) const;
   virtual bool ExtrStr(const char& js[], const int slen, int &i) const;
   
   virtual void Serialize(string &js, const bool bf = false, const bool bcoma = false) const;
   virtual bool Deserialize(const char& js[], const int slen, int &i);
public:

   JSONNode();
   JSONNode(JSONNode* aparent, const NodeType atype);
   JSONNode(const NodeType type, const string raw);
   JSONNode(const int raw);
   JSONNode(const long raw);
   JSONNode(const double raw, const int aprec = -100);
   JSONNode(const bool raw);
   JSONNode(const JSONNode& node);
   ~JSONNode();

   int Size() const { return ArraySize(m_e); }
   virtual bool IsNumeric() const { return m_type == Double || m_type == Integer; }
   
   virtual JSONNode* FindKey(const string akey) const;
   virtual JSONNode* HasKey(const string akey, const NodeType atype = Undefined) const;
   
   virtual JSONNode* operator[](const string akey);
   virtual JSONNode* operator[](const int i);
   
   void operator=(const JSONNode &other);
   void operator=(const int raw);
   void operator=(const long raw);
   void operator=(const double raw);
   void operator=(const bool raw);
   void operator=(const string raw);

   bool operator==(const int rhs) const { return m_iv == rhs; }
   bool operator==(const long rhs) const { return m_iv == rhs; }
   bool operator==(const double rhs) const { return m_dv == rhs; }
   bool operator==(const bool rhs) const { return m_bv == rhs; }
   bool operator==(const string rhs) const { return m_sv == rhs; }

   bool operator!=(const int rhs) const { return m_iv != rhs; }
   bool operator!=(const long rhs) const { return m_iv != rhs; }
   bool operator!=(const double rhs) const { return m_dv != rhs; }
   bool operator!=(const bool rhs) const { return m_bv != rhs; }
   bool operator!=(const string rhs) const { return m_sv != rhs; }

   long ToInteger() const { return m_iv; }
   double ToDouble() const { return m_dv; }
   bool ToBool() const { return m_bv; }
   string ToString() const { return m_sv; }
      
   virtual void Set(const JSONNode& node);
   virtual void Set(const JSONNode& list[]);
   
   virtual JSONNode* Add(const JSONNode& item);
   virtual JSONNode* Add(const int raw);
   virtual JSONNode* Add(const long raw);
   virtual JSONNode* Add(const double raw, const int aprec = -2);
   virtual JSONNode* Add(const bool raw);
   virtual JSONNode* Add(const string raw);
   virtual JSONNode* AddBase(const JSONNode &item);
   virtual JSONNode* New();
   virtual JSONNode* NewBase();
   
   virtual string Serialize() const;
   virtual bool Deserialize(const string js, const int acp = CP_ACP);
   virtual bool Deserialize(const char& js[], const int acp = CP_ACP);
};

int JSONNode::code_page = CP_ACP;

JSONNode::JSONNode() { 
   Clear();
}

JSONNode::JSONNode(JSONNode* aparent, const NodeType atype) {

   // Set the node to its base values
   Clear();
   
   // Set the node's type and parent
   m_type = atype; 
   m_parent = aparent;
}

JSONNode::JSONNode(const NodeType type, const string raw) { 
   Clear(); 
   FromString(type, raw);
}

JSONNode::JSONNode(const int raw) {

   // Set the node to its base value
   Clear(); 
   
   // Set the type to integer and set all the data fields
   m_type = Integer;
   m_iv = raw;
   m_dv = (double)m_iv;
   m_sv = IntegerToString(m_iv);
   m_bv = m_iv != 0;
}

JSONNode::JSONNode(const long raw) { 

   // Set the node to its base value
   Clear(); 
   
   // Set the type to integer and set all the data fields
   m_type = Integer;
   m_iv = raw;
   m_dv = (double)m_iv;
   m_sv = IntegerToString(m_iv);
   m_bv = m_iv!=0;
}

JSONNode::JSONNode(const double raw, const int aprec =- 100) {

   // First, set the node to its base value
   Clear();
   
   // Next, set the type to double and raw values for the double and precision
   m_type = Double;
   m_dv = raw;
   if (aprec > -100) {
      m_prec = aprec;
   }
   
   // Finally, set the other values for the node
   m_iv = (long)m_dv;
   m_sv = DoubleToString(m_dv, m_prec);
   m_bv = m_iv != 0;
}

JSONNode::JSONNode(const bool raw) {

   // Set the node to its base value
   Clear(); 
   
   // Set the type to Boolean and set all the data fields
   m_type = Bool;
   m_bv = raw;
   m_iv = m_bv;
   m_dv = m_bv;
   m_sv = IntegerToString(m_iv);
}

JSONNode::JSONNode(const JSONNode& node) {

   // Set the node to its base value
   Clear();
   
   // Copy the values from the input node to this one
   Copy(node);
}

JSONNode::~JSONNode() {
   Clear();
}

JSONNode* JSONNode::FindKey(const string akey) const { 
   for (int i = Size() - 1; i >= 0; --i) {
      if (m_e[i].m_key == akey) { 
         return GetPointer(m_e[i]);
      }
   }
   
   return NULL;
}

JSONNode* JSONNode::HasKey(const string akey, const NodeType atype = Undefined) const { 
   JSONNode* e = FindKey(akey);
   if (CheckPointer(e) != POINTER_INVALID) {
      if (atype == Undefined || atype == e.m_type) {
         return GetPointer(e);
      }
   }
      
   return NULL;
}

JSONNode* JSONNode::operator[](const string akey) { 
   
   // First, if the type of this node isn't defined then set it to object
   if (m_type == Undefined) {
      m_type = Object;
   }
   
   // Next, attempt to find the node associated with the key we're looking for; if we find it then return it
   JSONNode* v = FindKey(akey);
   if (v) {
      return v;
   }
   
   // Finally, if we didn't find it then return this
   JSONNode b(GetPointer(this), Undefined);
   b.m_key = akey;
   v = Add(b);
   return v;
}

JSONNode* JSONNode::operator[](const int i) {

   // First, if the type of this node is undefined then set it to array
   if (m_type == Undefined) {
      m_type = Array;
   }

   // Next, if the size is greater than the number of child elements, then attempt to get a pointer to this node
   while (i >= Size()) { 
      JSONNode b(GetPointer(this), Undefined);
      if (CheckPointer(Add(b)) == POINTER_INVALID) {
         return NULL; 
      }
   }
   
   // Finally, if we've reached this point, we know that the index is inside the bounds of our list of children,
   // so return the item at that index
   return GetPointer(m_e[i]);
}

void JSONNode::operator=(const JSONNode &other) { 
   Copy(other);
}

void JSONNode::operator=(const int raw) { 
   m_type = Integer;
   m_iv = raw;
   m_dv = (double)m_iv;
   m_bv = m_iv != 0;
}

void JSONNode::operator=(const long raw) { 
   m_type = Integer;
   m_iv = raw;
   m_dv = (double)m_iv;
   m_bv = m_iv != 0;
}

void JSONNode::operator=(const double raw) { 
   m_type = Double;
   m_dv = raw;
   m_iv = (long)m_dv;
   m_bv = m_iv != 0;
}

void JSONNode::operator=(const bool raw) {
   m_type = Bool;
   m_bv = raw;
   m_iv = (long)m_bv;
   m_dv = (double)m_bv;
}

void JSONNode::operator=(const string raw) { 
   m_type = (raw != NULL) ? String : Null;
   m_sv = raw;
   m_iv = StringToInteger(m_sv);
   m_dv = StringToDouble(m_sv);
   m_bv = raw != NULL;
}

string JSONNode::GetString(const char& js[], const int i, const int slen) const { 
   if (slen == 0) {
      return "";
   }
   
   char cc[];
   ArrayCopy(cc, js, 0, i, slen);
   return CharArrayToString(cc, 0, WHOLE_ARRAY, JSONNode::code_page);
}

void JSONNode::Set(const JSONNode& node) {

   // If the type was set to undefined then set it to object now
   if (m_type == Undefined) {
      m_type = Object;
   }
   
   // Copy the node data into this node
   CopyData(node);
}

void JSONNode::Set(const JSONNode& list[]) {

   // If the type was set to undefined then set it to array now
   if (m_type == Undefined) {
      m_type = Array;
   }

   // Set the size of the child array to the size of our list, or 100, whichever is less
   int n = ArrayResize(m_e, ArraySize(list), 100);
   
   // Iterate over each item in the list and add it to the child array
   for (int i = 0; i < n; ++i) { 
      m_e[i] = list[i];
      m_e[i].m_parent = GetPointer(this);
   }
}

JSONNode* JSONNode::Add(const JSONNode& item) {

   // If the type was set to undefined then set it to array now
   if (m_type == Undefined) {
      m_type = Array;
   }
   
   // Add the item to our list of elements and return the result
   return AddBase(item);
}

JSONNode* JSONNode::Add(const int raw) { 
   JSONNode item(raw);
   return Add(item);
}

JSONNode* JSONNode::Add(const long raw) { 
   JSONNode item(raw);
   return Add(item);
}

JSONNode* JSONNode::Add(const double raw, const int aprec = -2) { 
   JSONNode item(raw, aprec);
   return Add(item);
}

JSONNode* JSONNode::Add(const bool raw) { 
   JSONNode item(raw);
   return Add(item);
}

JSONNode* JSONNode::Add(const string raw) { 
   JSONNode item(String, raw);
   return Add(item);
}

JSONNode* JSONNode::AddBase(const JSONNode &item) { 
   
   // First, resize the child array
   int c = Size();
   ArrayResize(m_e, c + 1, 100);
   
   // Next, add the new item to the child array
   m_e[c] = item;
   m_e[c].m_parent = GetPointer(this);
   
   // Finally, return a pointer to the new child node
   return GetPointer(m_e[c]);
}

JSONNode* JSONNode::New() {

   // If the type was set to undefined then set it to array now
   if (m_type == Undefined) { 
      m_type = Array;
   }
   
   // Create a new node and return it
   return NewBase();
}

JSONNode* JSONNode::NewBase() { 
   int c = Size();
   ArrayResize(m_e, c + 1, 100);
   return GetPointer(m_e[c]);
}

string JSONNode::Serialize() const { 
   string js;
   Serialize(js);
   return js;
}

bool JSONNode::Deserialize(const string js, const int acp = CP_ACP) {
   
   // First, clear the node to ensure we get deterministic results
   Clear();
   JSONNode::code_page = acp;
   
   // Next, convert the string to a buffer
   char arr[];
   int slen = StringToCharArray(js, arr, 0, WHOLE_ARRAY, JSONNode::code_page);
   
   // Finally, deserialize the string to JSON
   int i = 0;
   return Deserialize(arr, slen, i);
}

bool JSONNode::Deserialize(const char& js[], const int acp = CP_ACP) {

   // Clear the node to ensure we get deterministic results
   Clear();
   JSONNode::code_page = acp;
   int i = 0;
   
   // Deserialize the string to JSON
   return Deserialize(js, ArraySize(js), i);
}

void JSONNode::Serialize(string& js, const bool bkey = false, const bool coma = false) const {
   
   // First, if the type is undefined then return as we have nothing to do
   if (m_type == Undefined) {
      return;
   }
   
   // Next, if we want to insert a comma then do so
   if (coma) {
      js += ",";
   }
   
   // Now, if we want to print the key then do so
   if (bkey) { 
      js += StringFormat("\"%s\":", m_key);
   }
   
   // Finally, print the data associated with this node based on its type
   int _n = Size();
   switch (m_type) {
   case Null: 
      js += "null";
      break;
   case Bool: 
      js += m_bv ? "true" : "false";
      break;
   case Integer:
      js += IntegerToString(m_iv);
      break;
   case Double:
      js += DoubleToString(m_dv, m_prec);
      break;
   case String:
      {
      
         // We have a string so escape it
         string ss = Escape(m_sv);
         
         // If the value we escaped is greater than zero then quote it; otherwise, set it to null
         if (StringLen(ss) > 0) {
            js += StringFormat("\"%s\"", ss);
         } else {
            js += "null";
         }
         
         break;
      }
   case Array: 
   
      // We have an array so set the opening bracket
      js += "[";
      
      // Iterate over each item in the child list and serialize each
      for (int i = 0; i < _n; i++) {
         m_e[i].Serialize(js, false, i > 0);
      }
      
      // Add the closing bracket
      js += "]";
      break;
   case Object: 
   
      // We have an object so set the opening curly bracket
      js += "{";
      
      // Iterate over each item in the child list and serialize each
      for (int i = 0; i < _n; i++) {
         m_e[i].Serialize(js, true, i > 0);
      }
      
      // Add the closing curly bracket
      js += "}";
      break;
   }
}

bool JSONNode::Deserialize(const char& js[], const int slen, int &i) {
      
   // Iterate over the string from the starting index to the ending index
   int i0 = i;
   for (; i < slen; i++) {
   
      // Get the character from the string; if it's zero then stop execution as we've
      // clearly reached the end of the string
      char c = js[i];
      if (c == 0) {
         break;
      }
   
      // Parse the character
      switch (c) {
      case '\t':
      case '\r':
      case '\n':
      case ' ':   // These cases are whitespace, ignore them
         i0 = i + 1;
         break;
      case '[':
         {
         
            // First, we have an array so iterate to the next character. Also, check that
            // the type of this node is undefined. If it's not then we have invalid JSON data
            i0 = i + 1;
            if (m_type != Undefined) { 
               Print(m_key + " " + string(__LINE__));
               return false;
            }
      
            // Next, set the type to Array and deserialize each element in the array
            i++;
            m_type = Array;
            JSONNode val(GetPointer(this), Undefined);
            while (val.Deserialize(js, slen, i)) {
      
               // First, the deserialization succeeded so check whether or not the type is undefined
               // If it isn't then we have a serialized element so add it to the node's children
               if (val.m_type != Undefined) {
                  Add(val);
               }
      
               // Next, if we have an numeric value or array then increment the counter to take in the
               // comma or closing bracket
               if (val.m_type == Integer || val.m_type == Double || val.m_type == Array) {
                  i++;
               }
               
               // Now, ensure that the value is cleared for the next deserialize call and to prevent memory
               // leaks. If the current character is a closing bracket then we've reached the end of the
               // array so break out of the loop
               val.Clear();
               val.m_parent = GetPointer(this);
               if (js[i] == ']') {
                  break;
               }
               
               // Finally, if we've reached this point then we need to increment the counter again. Check and
               // make sure we haven't walked off the string. If we have then we clearly have bad data so
               // return an error
               i++; 
               if (i >= slen) {
                  Print(m_key + " " + string(__LINE__));
                  return false;
               }
            }
      
            // Finally, return whether or not the last character we ingested was a closing bracket or a null
            return js[i] == ']' || js[i] == 0;
         }
      case ']': // We have a closing bracket, which means we ingested an array
      
         // Check that we're not at the root; if we are then the payload was corrupt
         if (!m_parent) {
            return false;
         }
         
         // If the parent type was array then return true; return false otherwise
         return m_parent.m_type == Array;
      case ':':   // We have a colon which means we have ingested a key and are preparing for a value
         {
            // First, check that the left-key is empty; if it is then we have a bad payload so return an error
            if (m_lkey == "") {
               Print(m_key + " " + string(__LINE__)); 
               return false;
            }
         
            // Next, create a new node and add it to the children of this node and set the associated key
            i++; 
            JSONNode val(GetPointer(this), Undefined);
            JSONNode *oc = Add(val);
            oc.m_key = m_lkey;
            m_lkey = "";
            
            // Finally, attempt to deserialize the value; if this fails then return an error
            if (!oc.Deserialize(js, slen, i)) { 
               Print(m_key + " " + string(__LINE__));
               return false;
            }
            
            break;
         }
      case ',':   // We have a comma so we probably finished ingesting a value
      
         // Increment to the next character
         i0 = i + 1;
         
         // If we're looking at the root but it is not an object then the payload is invalid so return 
         // an error. Otherwise, if the parent is not an array or object then the payload is invalid
         // so return an error. If the parent type is array and this type is undefined then we've finished
         // ingesting an array element so return true
         if (!m_parent && m_type != Object) { 
            Print(m_key + " " + string(__LINE__)); 
            return false;
         } else if (m_parent) {
         
            // If we've reached this point then we're not at the root. In this context, only arrays or objects
            // are valid parent types so return an error if this isn't the case
            if (m_parent.m_type != Array && m_parent.m_type != Object) {
               Print(m_key + " " + string(__LINE__)); 
               return false;
            }
         
            // If we happen to have an array and this type hasn't been defined it implies that we've finished
            // ingesting one value but haven't started ingesting the next value so return true
            if (m_parent.m_type == Array && m_type == Undefined) {
               return true;
            }
         }
         
         break;
      case '{':   // We have an opening curly bracket so we're looking at an object
   
         // First, increment the counter and ensure that the object isn't defined; if it is then the payload is corrupt
         // so return an error
         i0 = i + 1;
         if (m_type != Undefined) { 
            Print(m_key + " " + string(__LINE__));
            return false;
         }
         
         // Next, move to the next character and set the type of the object;
         i++;
         m_type = Object;
         
         // Now, attempt to deserialize the fields on this object; return an error if it failed
         if (!Deserialize(js, slen, i)) {
            Print(m_key + " " + string(__LINE__)); 
            return false;
         }
      
         // Finally, return true if we have a closing curly bracket or a null
         return js[i] == '}' || js[i] == 0;
      case '}': // We have a closing curly bracket, which means we ingested an object
         return m_type == Object;
      case 't': 
      case 'T':
      case 'f': 
      case 'F': // If we've reached this point then we're ingesting a Boolean value
   
         // First, check that the type isn't defined; if it is then we've got a corrupt payload
         // so return an error
         if (m_type != Undefined) { 
            Print(m_key + " " + string(__LINE__)); 
            return false;
         }
   
         // Next, set the type to Boolean 
         m_type = Bool;
         
         // Now, check if we have four characters left and then see if together
         // we can form the value "false"; if we were able to then return true here
         if (i + 4 < slen) {
            if (StringCompare(GetString(js, i, 5), "false", false) == 0) { 
               m_bv = false; 
               i += 4;
               return true;
            }
         } 
         
         // Check if we have three characters left and see if together we can
         // form the value "true"; if we were able to then return true here
         if (i + 3 < slen) { 
            if (StringCompare(GetString(js, i, 4), "true", false) == 0) { 
               m_bv = true;
               i += 3;
               return true;
            }
         }
   
         // If we've reached this point then we have an invalid Boolean value so return false
         Print(m_key + " " + string(__LINE__));
         return false;
      case 'n':
      case 'N':
      
         // First, check that the type isn't defined; if it is then we've got a corrupt payload
         // so return an error
         if (m_type != Undefined) { 
            Print(m_key + " " + string(__LINE__)); 
            return false;
         }
   
         // Set the type of this node to Null
         m_type = Null;
         
         // Check if there are three characters left and see if together we can form
         // the value "null"; if we were able to then return true here
         if (i + 3 < slen) {
            if (StringCompare(GetString(js, i, 4), "null", false) == 0) { 
               i += 3;
               return true;
            }
         }
         
         // If we've reached this point then we have an invalid NULL value so return false
         Print(m_key + " " + string(__LINE__)); 
         return false;
      case '0': 
      case '1': 
      case '2': 
      case '3': 
      case '4': 
      case '5': 
      case '6': 
      case '7': 
      case '8': 
      case '9': 
      case '-': 
      case '+': 
      case '.':   // If we've reached this point then we're ingesting a numeric value
         {
            // First, check that the type isn't defined; if it is then we've got a corrupt payload
            // so return an error
            if (m_type != Undefined) {
               Print(m_key + " " + string(__LINE__)); 
               return false;
            }
      
            // Next, iterate over all the characters and see if we can find a decimal place or
            // a value indicating that we're working with scientific notation. If this is the case
            // then we have a double
            bool dbl = false;
            int is = i;
            while (js[i] != 0 && i < slen) {
               i++;
               if (StringFind(num, GetString(js, i, 1)) < 0) {
                  break;
               }
               
               if (!dbl) {
                  dbl = js[i] == '.' || js[i]== 'e' || js[i]== 'E';
               }
            }
      
            // Now, get the string value of this field and then parse it as either a
            // double or integer based on the flag we just calculated
            m_sv = GetString(js, is, i - is);
            if (dbl) { 
               m_type = Double;
               m_dv = StringToDouble(m_sv);
               m_iv = (long)m_dv;
               m_bv = m_iv != 0;
            } else { 
               m_type = Integer;
               m_iv = StringToInteger(m_sv);
               m_dv = (double)m_iv;
               m_bv = m_iv != 0;
            }
      
            // Finally, decrement our counter as we moved one too far and return true
            i--;
            return true;
         }
      case '\"':  // If we've reached this point then we're ingesting a string
      
         // If we have an object then we need to check if we're looking at a field name
         // Otherwise, we need to check if we're working with a string value
         if (m_type == Object) {
         
            // Increment the counter and check if the string is a valid field name; if it's not
            // then return an error
            i++;
            int is = i;
            if (!ExtrStr(js, slen, i)) { 
               Print(m_key + " " + string(__LINE__));
               return false;
            }
            
            // Get the value of the string and set it to the left-key
            m_lkey = GetString(js, is, i - is);
         } else {
            
            // We're working with a string value so check that the type hasn't been defined yet. If it has
            // then return an error as the payload is invalid
            if (m_type != Undefined) { 
               Print(m_key + " " + string(__LINE__));
               return false;
            }
   
            // Set the node type to string and check that the string is valid; if it isn't then return an error
            m_type = String;
            i++;
            int is = i;
            if (!ExtrStr(js, slen, i)) { 
               Print(m_key + " " + string(__LINE__));
               return false;
            }
   
            // Get the value of the string and remove any quotes from it
            FromString(String, GetString(js, is, i - is));
            return true;
         }
   
         break;
      }
   }
   
   return true;
}

bool JSONNode::ExtrStr(const char& js[], const int slen, int &i) const {
   for (; js[i] != 0 && i < slen; i++) {
      
      // First, get the character at the current position
      char c = js[i];
      
      // Next, check if the character is a quote; if it is then we've reached the end of the
      // string so break out of the loop
      if (c == '\"') {
         break;
      }
      
      // Finally, check if we have an escape sequence; if we do parse the value
      if (c == '\\' && i + 1 < slen) {
         i++;
         c = js[i];
         switch (c) {
         case '/':
         case '\\':
         case '\"':
         case 'b':
         case 'f':
         case 'r':
         case 'n':
         case 't':
            break;
         case 'u': // \uXXXX
            i++;
            for (int j = 0; j < 4 && i < slen && js[i] != 0; j++, i++) {
               if (!((js[i] >= '0' && js[i] <= '9') || (js[i] >= 'A' && js[i] <= 'F') || (js[i] >= 'a' && js[i] <= 'f'))) { 
                  Print(m_key + " " + CharToString(js[i]) + " " + string(__LINE__));
                  return false; } // не hex
            }
            
            i--;
            break;
         }
      }
   }
   
   return true;
}

void JSONNode::Clear(NodeType jt = Undefined, bool savekey = false) { 
   
   // Set this node as the root node and reset the key
   m_parent = NULL;
   if (!savekey) {
      m_key = "";
   }
   
   // Set the other fields to their default values and reset our list of elements
   m_type = jt;
   m_bv = false;
   m_iv = 0;
   m_dv = 0; 
   m_prec = 8;
   m_sv = "";
   ArrayResize(m_e, 0, 100);
}

void JSONNode::FromString(const NodeType type, const string raw) {
   m_type = type;
   switch (m_type) {
   case Bool: 
      m_bv = StringToInteger(raw) != 0;
      m_iv = (long)m_bv;
      m_dv = (double)m_bv;
      m_sv = raw;
      break;
   case Integer: 
      m_iv = StringToInteger(raw);
      m_dv = (double)m_iv;
      m_sv = raw; 
      m_bv = m_iv != 0;
      break;
   case Double: 
      m_dv = StringToDouble(raw);
      m_iv = (long)m_dv;
      m_sv = raw;
      m_bv = m_iv != 0;
      break;
   case String:
      m_sv = Unescape(raw);
      m_type = m_sv != NULL ? String : Null;
      m_iv = StringToInteger(m_sv);
      m_dv = StringToDouble(m_sv);
      m_bv = m_sv != NULL;
      break;
   }
}

bool JSONNode::Copy(const JSONNode &node) {

   // Copy the value of the key from the node
   m_key = node.m_key;
   
   // Copy the data from the node
   CopyData(node);
   return true;
}

void JSONNode::CopyData(const JSONNode& node) { 
   m_type = node.m_type;
   m_bv = node.m_bv;
   m_iv = node.m_iv;
   m_dv = node.m_dv;
   m_prec = node.m_prec;
   m_sv = node.m_sv;
   CopyArray(node);
}

void JSONNode::CopyArray(const JSONNode& node) {
   int n = ArrayResize(m_e, ArraySize(node.m_e));
   for (int i = 0; i < n; i++) {
      m_e[i] = node.m_e[i];
      m_e[i].m_parent = GetPointer(this);
   }
}

string Escape(const string raw) {

   // First convert the raw string to an array of shorts
   ushort as[];
   int n = StringToShortArray(raw, as);
   
   // Next, create a buffer to store our escaped string
   ushort s[];
   if (ArrayResize(s, 2 * n) != 2 * n) {
      return NULL;
   }
   
   // Now, iterate over each character in our string and escape it if necessary
   // Set the result to its position in the buffer
   int j = 0;
   for (int i = 0; i < n; i++) {
      switch (as[i]) {
         case '\\': 
            s[j]='\\';
            j++;
            s[j]='\\';
            j++;
            break;
         case '"':
            s[j]='\\';
            j++;
            s[j]='"';
            j++;
            break;
         case '/':
            s[j]='\\';
            j++;
            s[j]='/';
            j++;
            break;
         case 8: 
            s[j]='\\';
            j++;
            s[j]='b';
            j++;
            break;
         case 12:
            s[j]='\\';
            j++;
            s[j]='f';
            j++;
            break;
         case '\n':
            s[j]='\\';
            j++;
            s[j]='n';
            j++;
            break;
         case '\r':
            s[j]='\\';
            j++;
            s[j]='r';
            j++;
            break;
         case '\t':
            s[j]='\\';
            j++;
            s[j]='t';
            j++;
            break;
         default: 
            s[j] = as[i];
            j++;
            break;
      }
   }
   
   // Finally, convert the portion of the buffer we used to a string and return it
   return ShortArrayToString(s, 0, j);
}

string Unescape(const string raw) {

   // First, convert the input string to an array of shorts
   ushort as[];
   int n = StringToShortArray(raw, as);
   
   // Next, create a buffer to store our character data
   ushort s[];
   if (ArrayResize(s, n) != n) {
      return NULL;
   }
   
   // Now, iterate over each character in our array and convert it to its unescaped equivalent
   int j=0, i=0;
   while (i < n) {
      ushort c = as[i];
      if (c == '\\' && i < n - 1) {
         switch (as[i+1]) {
         case '\\':
            c = '\\';
            i++;
            break;
         case '"':
            c = '"';
            i++;
            break;
         case '/':
            c = '/';
            i++;
            break;
         case 'b':
            c = 8; /*08='\b'*/
            i++;
            break;
         case 'f':
            c = 12; /*0c=\f*/
            i++;
            break;
         case 'n':
            c = '\n';
            i++;
            break;
         case 'r':
            c = '\r';
            i++;
            break;
         case 't':
            c = '\t';
            i++;
            break;
         case 'u': // \uXXXX
            {
               i += 2;
               ushort k = 0;
               for (int jj = 0; jj < 4 && i < n; jj++, i++) {
                  c = as[i]; ushort h = 0;
                  if (c >= '0' && c <= '9') {
                     h = c - '0';
                  } else if ( c >= 'A' && c <= 'F') {
                     h = c - 'A' + 10;
                  } else if (c >= 'a' && c <= 'f') {
                     h = c - 'a' + 10;
                  } else {
                     break;
                  }
               
                  k += h * (ushort)pow(16, (3 - jj));
               }
            
               i--;
               c = k;
               break;
            }   
         }
      }
      
      s[j] = c;
      j++;
      i++;
   }
   
   // Finally, convert the portion of the buffer we used to a string and return it
   return ShortArrayToString(s, 0, j);
}
