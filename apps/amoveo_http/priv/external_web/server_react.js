class LightWallet extends React.Component {
  constructor(props){
    super(props);
    let defaultNode = '127.0.0.1:8080';
    this.state = {
      node: defaultNode,
      height: '',
    }
    this.updateHeight = this.updateHeight.bind(this);
    this.axios = axios.create({
      baseURL: "http://" + defaultNode,
      timeout: 3000,
    })
  }
  updateNode(newValue) {
    this.setState({node: newValue}, () => {
      this.axios.baseURL = newValue
    })
  }
  updateHeight() {
    this.axios.post("", ["height"]).then(res => {
      this.setState({height: res.data[0]})
    });
  }
  render() {
    return (
      <div className="container">
        <h1>Amoveo Light Wallet</h1>

        <form className="form-inline">
          <div className="form-group mx-sm-3 mb-2">Node Address</div>
          <div className="form-group mb-2">
            <input type="text" className="form-control" value={this.state.node}
              onChange={(e) => this.updateNode(e.target.value)}/>
          </div>
          <div className="form-group mb-2">
            <select className="form-control"
              onChange={(e) => this.updateNode(e.target.value)}>
              <option value="127.0.0.1:8080">Local (127.0.0.1:8080)</option>
              <option value="159.89.106.253:8080">Zacks (159.89.106.253:8080)</option>
            </select>
          </div>
        </form>

        <form className="form-inline">
          <div className="form-group mx-sm-3 mb-2">Height</div>
          <div className="form-group mx-sm-3 mb-2">{this.state.height}</div>
          <button type="button" class="btn btn-primary mb-2"
            onClick={this.updateHeight}>Update</button>
        </form>
      </div>
    );
  }
}
const start = new Date().getTime();
setInterval(function() {
  ReactDOM.render(
    <LightWallet elapsed={new Date().getTime() - start} />,
    document.getElementById('server')
  );
}, 50);
