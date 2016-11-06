import React from 'react';
import './Facet.css';
import _ from 'lodash';

class FacetEntry extends React.Component {
  render() {
    return <div className="FacetEntry">
      <label>
        <input type="checkbox" value={this.props.selected} onClick={this.props.onClick} />
        {this.props.name}
      </label>
    </div>
  }
}

class Facet extends React.Component {

  getSortByFunction(name) {
    switch(name) {
    case "size":
      return function(size){
        switch (size) {
        case "S":
          return 0;
        case "M":
          return 1;
        case "L":
          return 2;
        case "XL":
          return 3;
        }
      };
      
    case "age":
      return function(age){
        switch (age) {
        case "Young":
          return 0;
        case "Adult":
          return 1;
        case "Senior":
          return 2;
        }
      };
      
    default:
      return _.identity;
      break;
    }
  }

  getSortedKeys(name, values) {
    let keys = _.keys(this.props.values);
    let sortBy = this.getSortByFunction(name);
    return _.sortBy(keys, sortBy);
  }
  
  render() {
    let andFunction = _.partial(this.props.andFunction, this.props.name);
    let andOrCandidate = _.includes(this.props.andAbleFacets, this.props.name);
    let andDom;
    if (andOrCandidate) {
      let isAnding = _.includes(this.props.andFacets, this.props.name);
      if (isAnding) {
        andDom = <span className="andor" onClick={andFunction}>match some</span>
      } else {
        andDom = <span className="andor" onClick={andFunction}>match all</span>
      }
    }

    let sortedKeys = this.getSortedKeys(this.props.name, this.props.values);

    return <div className="Facet noselect">
      <div className="FacetName">{this.props.name} {andDom}</div>
      {sortedKeys.map((value, key) => {
        let toggleFunction = _.partial(this.props.toggleFunction, value);
        return <FacetEntry key={key}
                           name={value}
                           onClick={toggleFunction}
                           selected={this.props.values[value]}>
               </FacetEntry>
      })}
    </div>
  }
}

Facet.propTypes = {
  id: React.PropTypes.number,
  name: React.PropTypes.string,
  values: React.PropTypes.object
}

export default Facet;
