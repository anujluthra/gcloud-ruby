# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Gcloud::Logging::Metric, :mock_logging do
  let(:metric_hash) { random_metric_hash }
  let(:metric_json) { metric_hash.to_json }
  let(:metric_grpc) { Google::Logging::V2::LogMetric.decode_json metric_json }
  let(:metric) { Gcloud::Logging::Metric.from_grpc metric_grpc, logging.service }

  it "knows its attributes" do
    metric.name.must_equal        metric_hash["name"]
    metric.description.must_equal metric_hash["description"]
    metric.filter.must_equal      metric_hash["filter"]
  end

  it "can save itself" do
    new_metric_description = "New Metric Description"
    new_metric_filter = "logName:syslog AND severity>=WARN"
    new_metric = Google::Logging::V2::LogMetric.new(
      name: metric.name,
      description: new_metric_description,
      filter: new_metric_filter
    )
    update_req = Google::Logging::V2::UpdateLogMetricRequest.new(
      metric_name: "projects/test/metrics/#{metric.name}",
      metric: new_metric
    )
    mock = Minitest::Mock.new
    mock.expect :update_log_metric, metric_grpc, [update_req]
    metric.service.mocked_metrics = mock

    metric.description = new_metric_description
    metric.filter = new_metric_filter
    metric.save

    mock.verify

    metric.must_be_kind_of Gcloud::Logging::Metric
    metric.description.must_equal new_metric_description
    metric.filter.must_equal new_metric_filter
  end

  it "can refresh itself" do
    get_req = Google::Logging::V2::GetLogMetricRequest.new metric_name: "projects/test/metrics/#{metric.name}"
    mock = Minitest::Mock.new
    mock.expect :get_log_metric, metric_grpc, [get_req]
    metric.service.mocked_metrics = mock

    metric.refresh!

    mock.verify
  end

  it "can delete itself" do
    delete_req = Google::Logging::V2::DeleteLogMetricRequest.new metric_name: "projects/test/metrics/#{metric.name}"
    mock = Minitest::Mock.new
    mock.expect :delete_log_metric, metric_grpc, [delete_req]
    metric.service.mocked_metrics = mock

    metric.delete

    mock.verify
  end
end
