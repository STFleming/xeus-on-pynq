
struct TensorShape {
  unsigned int height;
  unsigned int width;
  unsigned int channel;
  unsigned int size;
};

struct GraphInfo {
  struct TensorShape* inTensorList;
  struct TensorShape* outTensorList;
  std::vector<int> output_mapping;
};


inline float get_input_scale(const xir::Tensor* tensor) {
  int fixpos = tensor->template get_attr<int>("fix_point");
  return std::exp2f(1.0f * (float)fixpos);
}

inline float get_output_scale(const xir::Tensor* tensor) {
  int fixpos = tensor->template get_attr<int>("fix_point");
  return std::exp2f(-1.0f * (float)fixpos);
}

inline std::vector<std::unique_ptr<xir::Tensor>> cloneTensorBuffer(
    const std::vector<const xir::Tensor*>& tensors){
    auto ret = std::vector<std::unique_ptr<xir::Tensor>>{};
    auto type = xir::DataType::XINT;
    ret.reserve(tensors.size());
    for (const auto& tensor : tensors) {
            ret.push_back(std::unique_ptr<xir::Tensor>(xir::Tensor::create(
                tensor->get_name(), tensor->get_shape(), xir::DataType{type, 8u})));
    }
    return ret;
}

inline std::vector<const xir::Subgraph*> get_dpu_subgraph(
    const xir::Graph* graph){
    auto root = graph->get_root_subgraph();
    auto children = root->children_topological_sort();
    auto ret = std::vector<const xir::Subgraph*>();
    for (auto c : children) {
        CHECK(c->has_attr("device"));
        auto device = c->get_attr<std::string>("device");
        if (device == "DPU") {
            ret.emplace_back(c);
        }
    }
    return ret;
}

class CpuFlatTensorBuffer : public vart::TensorBuffer {
    public:
        explicit CpuFlatTensorBuffer(void* data, const xir::Tensor* tensor)
            : TensorBuffer{tensor}, data_{data} {}
        virtual ~CpuFlatTensorBuffer() = default;

    public:
        virtual std::pair<uint64_t, size_t> data(
        const std::vector<int> idx) override {
            uint32_t size = std::ceil(
                tensor_->get_data_type().bit_width / 8.f);
            if (idx.size() == 0) {
                return {reinterpret_cast<uint64_t>(data_),
                        tensor_->get_element_num() * size};
            }
            auto dims = tensor_->get_shape();
            auto offset = 0;
            for (auto k = 0; k < dims.size(); k++) {
                auto stride = 1;
                for (auto m = k + 1; m < dims.size(); m++) {
                    stride *= dims[m];
                }
                offset += idx[k] * stride;
            }
            auto elem_num = tensor_->get_element_num();
            return {reinterpret_cast<uint64_t>(data_) + offset * size,
                    (elem_num - offset) * size};
        }
        private:
            void* data_;
};
