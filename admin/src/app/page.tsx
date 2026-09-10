/**
 * Foundation page.
 *
 * NOT the dashboard. It renders the shell and the UI primitives so the foundation can be
 * reviewed in a browser before any real screen depends on it, and it states plainly what
 * has and has not been built. The Dashboard, Users, Content and Analytics screens are
 * separate tasks.
 */
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { EmptyState, ErrorState, LoadingState, Skeleton } from "@/components/ui/States";
import { Table, TBody, TD, TH, THead, TR } from "@/components/ui/Table";
import { AppShell } from "@/components/layout/AppShell";

export default function Page() {
  return (
    <AppShell
      title="Foundation"
      description="Shell and UI primitives. No product screens are built yet."
    >
      <div className="flex flex-col gap-6">
        <Card
          title="Status"
          description="What exists in this repository right now."
        >
          <ul className="flex flex-col gap-2 text-sm text-text-secondary">
            <li>App shell, sidebar, header and content container are implemented.</li>
            <li>Design tokens match the Flutter app&apos;s semantic palette.</li>
            <li>
              Users, Content, Analytics, Subscriptions, Notifications and System are
              navigation entries only, disabled until their tasks land.
            </li>
            <li>
              No data is fetched. The admin reads only through the Go backend, never a
              database.
            </li>
          </ul>
        </Card>

        <Card title="Buttons">
          <div className="flex flex-wrap items-center gap-3">
            <Button>Primary</Button>
            <Button variant="secondary">Secondary</Button>
            <Button variant="ghost">Ghost</Button>
            <Button disabled>Disabled</Button>
            <Button isLoading>Loading</Button>
          </div>
        </Card>

        <Card title="Input">
          <div className="flex max-w-md flex-col gap-4">
            <Input label="Label" placeholder="Placeholder" helperText="Helper text" />
            <Input label="With error" errorText="This field is required." />
          </div>
        </Card>

        <Card title="Table" description="Semantic markup, numeric columns aligned">
          <Table caption="Example data">
            <THead>
              <TR>
                <TH>Word</TH>
                <TH>Level</TH>
                <TH numeric>Attempts</TH>
                <TH numeric>Avg score</TH>
              </TR>
            </THead>
            <TBody>
              <TR>
                <TD>think</TD>
                <TD>A2</TD>
                <TD numeric>1,204</TD>
                <TD numeric>72.4</TD>
              </TR>
              <TR>
                <TD>through</TD>
                <TD>B1</TD>
                <TD numeric>986</TD>
                <TD numeric>64.1</TD>
              </TR>
            </TBody>
          </Table>
        </Card>

        <div className="grid gap-6 md:grid-cols-3">
          <Card title="Loading">
            <LoadingState />
          </Card>
          <Card title="Error">
            <ErrorState
              message="We could not reach the API."
              requestId="req_example_0000"
            />
          </Card>
          <Card title="Empty">
            <EmptyState title="Nothing here yet" message="Rows will appear here." />
          </Card>
        </div>

        <Card title="Skeleton">
          <div className="flex flex-col gap-2">
            <Skeleton />
            <Skeleton className="h-4 w-2/3" />
            <Skeleton className="h-4 w-1/3" />
          </div>
        </Card>
      </div>
    </AppShell>
  );
}
