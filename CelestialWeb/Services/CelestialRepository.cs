using Microsoft.Data.SqlClient;
using CelestialWeb.Models;

namespace CelestialWeb.Services;

public class CelestialRepository
{
    private readonly string _connectionString;

    public CelestialRepository(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("CelestialDatabase")
            ?? throw new InvalidOperationException("Connection string 'CelestialDatabase' not found.");
    }

    public async Task<List<string>> GetBodyTypesAsync()
    {
        var result = new List<string>();
        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync();
        await using var cmd = new SqlCommand("SELECT TypeName FROM dbo.BodyType ORDER BY TypeName;", conn);
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
            result.Add(reader.GetString(0));
        return result;
    }

    public async Task<(List<CelestialBody> Items, int Total)> SearchAsync(CelestialQuery q)
    {
        var where = new List<string>();
        var parameters = new List<SqlParameter>();

        if (!string.IsNullOrWhiteSpace(q.Name))
        {
            where.Add("(cb.Name LIKE @Name OR cb.CommonName LIKE @Name)");
            parameters.Add(new SqlParameter("@Name", $"%{q.Name}%"));
        }
        if (!string.IsNullOrWhiteSpace(q.BodyType))
        {
            where.Add("bt.TypeName = @BodyType");
            parameters.Add(new SqlParameter("@BodyType", q.BodyType));
        }
        if (q.MinMagnitude.HasValue)
        {
            where.Add("cb.Magnitude >= @MinMagnitude");
            parameters.Add(new SqlParameter("@MinMagnitude", q.MinMagnitude.Value));
        }
        if (q.MaxMagnitude.HasValue)
        {
            where.Add("cb.Magnitude <= @MaxMagnitude");
            parameters.Add(new SqlParameter("@MaxMagnitude", q.MaxMagnitude.Value));
        }
        if (q.MinRA.HasValue)
        {
            where.Add("cb.RA_Hours >= @MinRA");
            parameters.Add(new SqlParameter("@MinRA", q.MinRA.Value));
        }
        if (q.MaxRA.HasValue)
        {
            where.Add("cb.RA_Hours <= @MaxRA");
            parameters.Add(new SqlParameter("@MaxRA", q.MaxRA.Value));
        }
        if (q.MinDEC.HasValue)
        {
            where.Add("cb.DEC_Degrees >= @MinDEC");
            parameters.Add(new SqlParameter("@MinDEC", q.MinDEC.Value));
        }
        if (q.MaxDEC.HasValue)
        {
            where.Add("cb.DEC_Degrees <= @MaxDEC");
            parameters.Add(new SqlParameter("@MaxDEC", q.MaxDEC.Value));
        }

        var whereClause = where.Count > 0 ? "WHERE " + string.Join(" AND ", where) : string.Empty;

        var countSql = $@"
SELECT COUNT(*) FROM dbo.CelestialBody cb
JOIN dbo.BodyType bt ON bt.BodyTypeID = cb.BodyTypeID
LEFT JOIN dbo.Constellation c ON c.ConstellationID = cb.ConstellationID
{whereClause};";

        var dataSql = $@"
SELECT cb.BodyID, cb.Name, cb.CommonName, bt.TypeName AS BodyType,
       cb.Magnitude, cb.RA_Hours, cb.RA_Degrees, cb.DEC_Degrees,
       cb.Distance_LY, c.Name AS Constellation, c.Abbreviation AS ConstellationAbbr,
       parent.Name AS OrbitsPlanet,
       cb.Description
FROM dbo.CelestialBody cb
JOIN dbo.BodyType bt ON bt.BodyTypeID = cb.BodyTypeID
LEFT JOIN dbo.Constellation c ON c.ConstellationID = cb.ConstellationID
LEFT JOIN dbo.Moon mn ON mn.BodyID = cb.BodyID
LEFT JOIN dbo.CelestialBody parent ON parent.BodyID = mn.ParentBodyID
{whereClause}
ORDER BY cb.Name
OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;";

        await using var conn = new SqlConnection(_connectionString);
        await conn.OpenAsync();

        int total;
        await using (var countCmd = new SqlCommand(countSql, conn))
        {
            countCmd.Parameters.AddRange(parameters.Select(p => new SqlParameter(p.ParameterName, p.Value)).ToArray());
            total = (int)(await countCmd.ExecuteScalarAsync() ?? 0);
        }

        var items = new List<CelestialBody>();
        await using (var dataCmd = new SqlCommand(dataSql, conn))
        {
            foreach (var p in parameters)
                dataCmd.Parameters.AddWithValue(p.ParameterName, p.Value);
            dataCmd.Parameters.AddWithValue("@Offset", (q.Page - 1) * q.PageSize);
            dataCmd.Parameters.AddWithValue("@PageSize", q.PageSize);

            await using var reader = await dataCmd.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                items.Add(new CelestialBody
                {
                    BodyID = reader.GetInt64(0),
                    Name = reader.GetString(1),
                    CommonName = reader.IsDBNull(2) ? null : reader.GetString(2),
                    BodyType = reader.GetString(3),
                    Magnitude = reader.IsDBNull(4) ? null : reader.GetDecimal(4),
                    RA_Hours = reader.IsDBNull(5) ? null : reader.GetDecimal(5),
                    RA_Degrees = reader.IsDBNull(6) ? null : reader.GetDecimal(6),
                    DEC_Degrees = reader.IsDBNull(7) ? null : reader.GetDecimal(7),
                    Distance_LY = reader.IsDBNull(8) ? null : reader.GetDecimal(8),
                    Constellation = reader.IsDBNull(9) ? null : reader.GetString(9),
                    ConstellationAbbr = reader.IsDBNull(10) ? null : reader.GetString(10),
                    OrbitsPlanet = reader.IsDBNull(11) ? null : reader.GetString(11),
                    Description = reader.IsDBNull(12) ? null : reader.GetString(12),
                });
            }
        }

        return (items, total);
    }
}